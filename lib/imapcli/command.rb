module Imapcli
  require 'pp'
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

    def stats(mailbox_names)
      perform do |output|
        mailboxes = mailbox_names.map { |name| @client.find_mailbox(name) }.compact
        total_count = mailboxes.inject(mailboxes.length) do |sum, mailbox|
          sum += mailbox.count_sub_mailboxes
        end
        current_count = 0
        mailboxes.each do |mailbox|
          collect_stats_recursively(output, mailbox, 3) do
            current_count += 1
            yield current_count, total_count if block_given?
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

    def collect_stats(mailbox)
      yield if block_given?
      if mailbox.name
        mailbox.collect_stats(@client)
        [
          mailbox.full_name,
          mailbox.stats.count,
          format_kib(mailbox.stats.total_size),
          format_kib(mailbox.stats.min_size),
          format_kib(mailbox.stats.quartile_1_size),
          format_kib(mailbox.stats.median_size),
          format_kib(mailbox.stats.quartile_3_size),
          format_kib(mailbox.stats.max_size)
        ]
      else
        []
      end
    end

    def collect_stats_recursively(output, mailbox, max_level = nil)
      output << collect_stats(mailbox, &Proc.new)
      if mailbox.has_children? && max_level && mailbox.level < max_level
        mailbox.children.each do |child|
          collect_stats_recursively(output, child, max_level, &Proc.new)
        end
      end
    end

    def format_kib(kib)
      kib.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse + ' kiB'.freeze
    end

  end
end
