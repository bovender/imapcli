module Imapcli
  require 'pp'
  # Provides entry points for Imapcli.
  #
  # Most of the methods in this class return
  class Command
    def initialize(client)
      raise ArgumentError, 'Imapcli::Client is required' unless client && client.is_a?(Imapcli::Client)
      @client = client
    end

    # Checks if the server accepts the login with the given credentials.
    #
    # Returns true if successful, false if not.
    def check
      @client.login
    end

    # Collects basic information about the server.
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
        traverse_mailbox_tree(output, @client.mailbox_root, 0)
      end
    end

    # Collects statistics about mailboxes.
    #
    # If a block is given, it is called with the current mailbox count and the
    # total mailbox count so that current progress can be computed.
    def stats(mailbox_names, options = {})
      perform do |output|
        # Map the command line arguments to Imapcli::Mailbox objects
        mailboxes = find_mailboxes(mailbox_names)
        current_count, total_count = 0, mailboxes.inject(0) { |sum, mailbox| sum += mailbox.count }
        total_stats = Stats.new
        mailboxes.each do |mailbox|
          max_level = determine_max_level(mailbox, options)
          mailbox.collect_stats(@client, max_level) do |stats|
            total_stats.add(stats)
            current_count += 1
            yield current_count, total_count if block_given?
          end
        end
        list = mailbox_trees_to_sorted_list(mailboxes, options)
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

    def traverse_mailbox_tree(output, mailbox, depth = 0)
      if mailbox.has_children?
        indent = ('  ' * depth) || ''
        mailbox.children.each do |child|
          output << indent + '- ' + child.name
          output << traverse_mailbox_tree(output, child, depth + 1)
        end
      end
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

    # Finds and returns mailboxes based on mailbox names.
    def find_mailboxes(names)
      if names && names.length > 1
        Imapcli::Mailbox.consolidate(
          names.map { |name| @client.find_mailbox(name) }.compact
        )
      else
        [@client.mailbox_root]
      end
    end

    # Determines the maximum level for mailbox statistics.
    #
    # If the mailbox is the root mailbox, the entire mailbox tree is traversed
    # by default, unless a :depth option limits the maximum depth.
    #
    # If the mailbox is not the root mailbox, by default no recursion will be
    # performed, unless a :depth option requests a particular depth.
    def determine_max_level(mailbox, options = {})
      if mailbox.is_root?
        options[:depth]
      else
        depth = options[:depth] || 0
        mailbox.level + depth
      end
    end

    def mailbox_trees_to_sorted_list(mailboxes, options = {})
      list = mailboxes.inject([]) { |l, m| l + m.to_list }.uniq
      case options[:sort]
      when :count
        list.sort_by { |mailbox| mailbox.stats.count }
      when :total_size
        list.sort_by { |mailbox| mailbox.stats.total_size }
      when :median_size
        list.sort_by { |mailbox| mailbox.stats.median_size }
      when :min_size
        list.sort_by { |mailbox| mailbox.stats.min_size }
      when :q1
        list.sort_by { |mailbox| mailbox.stats.q1 }
      when :q3
        list.sort_by { |mailbox| mailbox.stats.q3 }
      when :max_size
        list.sort_by { |mailbox| mailbox.stats.max_size }
      else
        list
      end
    end

  end
end
