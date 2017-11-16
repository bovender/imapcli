module Imapcli
  # Provides entry points for Imapcli.
  #
  # Most of the methods in this class return
  class Command
    def initialize(client)
      raise 'Imapcli::Client is required' unless client
      @client = client
    end

    # Checks if the server accepts the login with the given credentials.
    #
    # Returns true if successful, false if not.
    def check
      @client.login
    end

    # Collects basic information about the server.
    #
    # The block is called repeatedly with informative messages.
    # If login is not successful, an error will be raised.
    def info
      perform do |output|
        output << "greeting: #{@client.greeting}"
        output << "capability: #{@client.capability.join(' ')}"
        output << "hierarchy separator: #{@client.separator}"
        if @client.supports_quota
          usage = Filesize.from(@client.quota[0] + ' kB').pretty
          available = Filesize.from(@client.quota[1] + ' kB').pretty
          output << "quota: #{usage} used, #{available} available (#{@client.quota[2].round(1)}%)"
        else
          output << "quota: IMAP QUOTA extension not supported by this server"
        end
      end
    end

    def list
      perform do |output|
        @client.collect_stats
        output << "mailboxes (folders) tree:"
        output += traverse_mailbox_tree @client.mailbox_tree, 0
      end
    end

    def stats(mailboxes)
      perform do |output|
        mailboxes.each do |name|
          if mailbox = @client.find_mailbox(name)
            mailbox.collect_stats(@client)
            output << [
              mailbox.full_name,
              mailbox.stats[:count],
              format_kib(mailbox.stats[:size]),
              format_kib(mailbox.stats[:min]),
              format_kib(mailbox.stats[:q1]),
              format_kib(mailbox.stats[:median]),
              format_kib(mailbox.stats[:q3]),
              format_kib(mailbox.stats[:max])
            ]
          else
            output << [ self.class.unknown_mailbox_prefix + name ] + Array.new(7, '---')
          end
        end
      end
    end

    def self.unknown_mailbox_prefix
      '!!! '
    end

    private

    def perform
      output = []
      if @client.login
        yield output
      else
        raise 'unable to log into server'
      end
      output
    end

    def traverse_mailbox_tree(mailbox, depth = 0)
      output = []
      if mailbox.has_children?
        indent = ('  ' * depth) || ''
        mailbox.children.each do |child|
          output << indent + '- ' + child.name
          output += traverse_mailbox_tree child, depth + 1
        end
      end
      output
    end

    def format_kib(kib)
      kib.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse + ' kiB'.freeze
    end

  end
end
