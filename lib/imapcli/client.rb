module Imapcli
  class Client
    require 'net/imap'

    attr_accessor :server, :user, :pass
    attr_reader :responses

    def initialize(server, user, pass)
      @server, @user, @pass = server, user, pass
      clear_responses
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
      begin
        @connection ||= Net::IMAP.new(@server, 993, true)
      rescue => error
        log_error error
      end
    end

    def login
      begin
        examine_response connection.login(@user, @pass)
      rescue Net::IMAP::NoResponseError => error
        log_error error
      end
    end

    def folders
      @folders ||= @server.list('', '*')
    end

    def folder_names
      folders.map { |folder| folder.name }
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

  end # class Client
end # module Imapcli
