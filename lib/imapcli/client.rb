module Imapcli
  class Client
    require 'net/imap'

    attr_accessor :server, :user, :pass

    def initialize(server, user, pass)
      @server, @user, @pass = server, user, pass
      @server = Net::IMAP.new(@server, 993, true)
      @server.login(@user, @pass)
    end

    ## Perform basic sanity check on server name
    #
    # Note that a propery regex for an FQDN is hard to achieve.
    # See https://stackoverflow.com/a/106223/270712 and elsewhere.
    def server_valid?
      @server =~ /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/
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

    def folders
      @folders ||= @server.list('', '*')
    end

    def folder_names
      folders.map { |folder| folder.name }
    end

  end
end
