# frozen_string_literal: true

module Imapcli
  # Wrapper for Net::IMAP
  class Client
    require 'net/imap'
    require 'filesize'
    require 'descriptive_statistics'

    attr_accessor :port, :user, :pass
    attr_reader :responses

    ## Initializs the Client class.
    ##
    ## +server_with_optional_port+ is the server's domain name; the port may be
    ## added following a colon. Default port is 993.
    ## +user+ is the user (account) name to log into the server.
    ## +pass+ is the password to log into the server.
    def initialize(server_with_optional_port, user, pass)
      @port = 993 # default
      self.server, @user, @pass = server_with_optional_port, user, pass
      clear_log
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

    # Perform basic sanity check on server name
    #
    # Note that a propery regex for an FQDN is hard to achieve.
    # See https://stackoverflow.com/a/106223/270712 and elsewhere.
    def server_valid?
      @server.match? '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'
    end

    # Perform *very* basic sanity check on user name
    #
    def user_valid?
      @user&.length > 0
    end

    # Returns true if both server and user name are valid.
    def valid?
      server_valid? && user_valid?
    end

    # Clears the server response log
    def clear_log
      @log = []
    end

    # Returns the last response from the server
    def last_response
      @log.last
    end

    # Returns a connection to the server.
    #
    # The value is cached.
    def connection
      @connection ||= Net::IMAP.new(@server, @port, true)
    end

    # Logs in to the server.
    #
    # Returns true if login was successful, false if not (e..g, invalid
    # credentials).
    def login
      raise('no connection to a server') unless connection
      begin
        response_ok? connection.login(@user, @pass)
      rescue Net::IMAP::NoResponseError => error
        log_error error
      end
    end

    # Logs out of the server.
    def logout
      # access instance variable to avoid creating a new connection
      @connection.logout if @connection
    end

    # Returns the server's greeting (which may reveal the server software name
    # such as 'Dovecot').
    def greeting
      query_server { connection.greeting.data.text.strip }
    end

    # Returns the server's capabilities.
    def capability
      @capability ||= query_server { connection.capability }
    end

    # Returns the character that is used to separate nested mailbox names.
    def separator
      @separator ||= query_server { connection.list('', '')[0].delim }
    end

    # Returns true if the server supports the IMAP QUOTA extension.
    def supports_quota
      capability.include? 'QUOTA'
    end

    # If the server +supports_quota+, returns an array containing the current
    # usage (in kiB), the total quota (in kiB), and the percent usage.
    def quota
      if supports_quota
        @quota ||= begin
          info = query_server { @connection.getquotaroot('INBOX')[1] }
          percent = info.quota.to_i > 0 ? info.usage.to_i.fdiv(info.quota.to_i) * 100 : nil
          [ info.usage, info.quota, percent ]
        end
      end
    end

    # Returns an array of message indexes for a mailbox.
    #
    # The value is currently NOT cached.
    def messages(mailbox)
      query_server { connection.examine(mailbox) }
      query_server { connection.search('ALL') }
    end

    # Examines a mailbox and returns statistics about the messages in it.
    #
    # Returns an array with the following keys:
    # * :count: Total count of messages.
    # * :size: Total size of all messages in bytes.
    # * :min: Size of the smallest message.
    # * :q1: First quartile of message sizes.
    # * :median: Median of message sizes.
    # * :q3: Third quartile of messages sizes.
    # * :max: Size of largest message.
    def message_sizes(mailbox)
      # Could use the EXAMINE command to get the number of messages in a mailbox,
      # but we need to retrieve an array of message indexes anyway (to compute
      # the total mailbox size), so we can save one roundtrip to the server.
      # query_server { connection.examine(mailbox) }
      # total = connection.responses['EXISTS'][0]
      # unseen = query_server { connection.search('UNSEEN') }.length
      messages = messages(mailbox)
      if messages.length > 0
        query_server { connection.fetch(messages, 'RFC822.SIZE').map { |f| f.attr['RFC822.SIZE'] } }
      else
        []
      end
    end

    # Collects stats for all mailboxes recursively.
    def collect_stats
      mailbox_root.collect_stats(self)
    end

    # Gets a list of Net::IMAP::MailboxList items, one for each mailbox.
    #
    # The value is cached.
    def mailboxes
      @mailboxes ||= query_server { @connection.list('', '*') }
    end

    # Returns a tree of +Imapcli::Mailbox+ objects.
    #
    # The value is cached.
    def mailbox_root
      @mailbox_root ||= Mailbox.new(mailboxes)
    end

    # Attempts to locate a given +mailbox+ in the +mailbox_root+.
    #
    # Returns nil if the mailbox is not found.
    def find_mailbox(mailbox)
      mailbox_root.find_sub_mailbox(mailbox, separator)
    end

    private

    def response_ok?(response)
      @log << response
      response.name == 'OK'
    end

    def log_error(error)
      @log << error
      false
    end

    # Wrapper function that can be used to execute code that queries the server.
    #
    # This function ensures that there is a valid +connection+ and raises an
    # error if not. The code that queries the server must be contained in the
    # +block+, and the +block+'s return value is returned by this function.
    # The +connection+'s responses are logged.
    def query_server(&block)
      raise('no connection to a server') unless connection
      result = yield
      @log << connection.responses
      result
    end

  end # class Client
end # module Imapcli
