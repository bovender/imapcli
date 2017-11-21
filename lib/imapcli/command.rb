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

    # Lists all mailboxes
    def list
      perform do |output|
        output += traverse_mailbox_tree @client.mailbox_tree, 0
      end
    end

    # Collects statistics about mailboxes.
    #
    # If a block is given, it is called with the current mailbox count and the
    # total mailbox count so that current progress can be computed.
    def stats(mailbox_names)
      perform do |output|
        # Map the command line arguments to Imapcli::Mailbox objects
        mailboxes = Imapcli::Mailbox.consolidate(
          mailbox_names.map { |name| @client.find_mailbox(name) }.compact
        )
        total_count = mailboxes.inject(0) { |sum, mailbox| sum += mailbox.count }
        current_count = 0
        total_stats = Stats.new
        mailboxes.each do |mailbox|
          mailbox.collect_stats(@client) do |stats|
            total_stats.add(stats)
            current_count += 1
            yield current_count, total_count if block_given?
          end
        end
        list = mailboxes.inject([]) { |l, m| l + m.to_list }.uniq
        list.each do |mailbox|
          output << stats_to_table(mailbox.full_name, mailbox.stats)
        end
        output << Array.new(8, '======')
        output << stats_to_table('Total', total_stats)
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

    def stats_to_table(first_cell, stats)
      [
        first_cell,
        stats.count,
        format_kib(stats.total_size),
        format_kib(stats.min_size),
        format_kib(stats.quartile_1_size),
        format_kib(stats.median_size),
        format_kib(stats.quartile_3_size),
        format_kib(stats.max_size)
      ]
    end

    def format_kib(kib)
      kib.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse + ' kiB'.freeze
    end

  end
end
