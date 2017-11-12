module Imapcli
  # Wrapper for Net::IMAP
  class Client
    require 'net/imap'
    require 'filesize'

    attr_accessor :port, :user, :pass
    attr_reader :responses

    def initialize(server_with_optional_port, user, pass)
      @port = 993 # default
      self.server, @user, @pass = server_with_optional_port, user, pass
      clear_responses
    end

    # Attribute reader for the server domain name
    def server
      @server
    end

    # Attribute writer for the server domain name; a port may be appended with
    # a colon.
    #
    # If no port is appended, the default port (993) will be used.
    def server=(server_with_optional_port)
      match = server_with_optional_port.match('^([^:]+):(\d+)$')
      if match
        @server = match[1]
        @port = match[2].to_i
      else
        @server = server_with_optional_port
      end
    end

    ## Perform basic sanity check on server name
    #
    # Note that a propery regex for an FQDN is hard to achieve.
    # See https://stackoverflow.com/a/106223/270712 and elsewhere.
    def server_valid?
      @server.match? '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'
    end

    ## Perform *very* basic sanity check on user name
    #
    def user_valid?
      @user&.length > 0
    end

    ## Returns true if the server name is valid and the user too.
    def valid?
      server_valid? && user_valid?
    end

    def clear_responses
      @responses = []
    end

    def last_response
      @responses.last
    end

    def connection
      @connection ||= Net::IMAP.new(@server, @port, true)
    end

    def login
      raise('no connection to a server') unless connection
      begin
        examine_response connection.login(@user, @pass)
      rescue Net::IMAP::NoResponseError => error
        log_error error
      end
    end

    def logout
      @connection.logout if @connection
    end

    def greeting
      raise('no connection to a server') unless connection
      connection.greeting.data.text.strip
    end

    def capability
      raise('no connection to a server') unless connection
      @capability ||= log { connection.capability }
    end

    def separator
      raise('no connection to a server') unless connection
      @separator ||= log { connection.list('', '')[0].delim }
    end

    def supports_quota
      capability.include? 'QUOTA'
    end

    def quota
      if supports_quota
        @quota ||= begin
          info = log { @connection.getquotaroot('INBOX')[1] }
          percent = info.quota.to_i > 0 ? info.usage.to_i.fdiv(info.quota.to_i) * 100 : nil
          [ info.usage, info.quota, percent ]
        end
      end
    end

    def examine(mailbox)
      raise('no connection to a server') unless connection
      # Could use the EXAMINE command to get the number of messages in a mailbox,
      # but we need to retrieve an array of message indexes anyway (to compute
      # the total mailbox size), so we can save one roundtrip to the server.
      # log { connection.examine(mailbox) }
      # total = connection.responses['EXISTS'][0]
      # unseen = log { connection.search('UNSEEN') }.length
      { total: total, unseen: unseen }
    end

    def get_size(mailbox)
      raise('no connection to a server') unless connection
      log do
        connection.fetch(1..2, 'RFC822.SIZE').inject(0) { |sum, fetch_data| sum += fetch_data.attr['RFC822.SIZE'] }
      end
    end

    def mailboxes
      @mailboxes ||= log { @connection.list('', '*') }
    end

    def mailbox_tree
      @mailbox_tree ||= Mailbox.new('', mailboxes)
    end

    private

    def examine_response(response)
      @responses << response
      response.name == 'OK'
    end

    def log_error(error)
      @responses << error
      false
    end

    def log(&block)
      result = yield
      @responses << connection.responses
      result
    end

  end # class Client
end # module Imapcli
