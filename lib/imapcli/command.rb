# frozen_string_literal: true

module Imapcli
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
      perform do
        output = []
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
      perform do
        traverse_mailbox_tree(@client.mailbox_root)
      end
    end

    # Collects statistics about mailboxes.
    #
    # If a block is given, it is called with the current mailbox count and the
    # total mailbox count so that current progress can be computed.
    def stats(mailbox_names = [], options = {})
      mailbox_names = [mailbox_names] unless mailbox_names.is_a? Array
      perform do
        output = []
        # Map the command line arguments to Imapcli::Mailbox objects
        mailboxes = find_mailboxes(mailbox_names)
        list = mailboxes.inject([]) do |ary, mailbox|
          ary + mailbox.to_list(determine_max_level(mailbox, options))
        end
        raise 'mailbox not found' unless list.count > 0
        current_count = 0
        yield list.length if block_given?
        total_stats = Stats.new
        list.each do |mailbox|
          # Since we are working on a flat list of mailboxes, set the maximum
          # level to 0 when collecting stats.
          mailbox.collect_stats(@client, 0) do |stats|
            total_stats.add(stats)
            current_count += 1
            yield current_count if block_given?
          end
        end
        sorted_list(list, options).each do |mailbox|
          output << stats_to_table(mailbox.full_name, mailbox.stats)
        end
        # output << Array.new(8, '======')
        output << stats_to_table('Total', total_stats) if list.length > 1
        output
      end
    end

    def self.unknown_mailbox_prefix
      '!!! '
    end

    private

    def perform
      if @client.login
        yield
      else
        raise 'unable to log into server'
      end
    end

    def traverse_mailbox_tree(mailbox, depth = 0)
      this = mailbox.is_imap_mailbox? ? ["#{'  ' * [depth - 1, 0].max}- #{mailbox.name}"] : []
      mailbox.children.inject(this) do |ary, child|
        ary + traverse_mailbox_tree(child, depth + 1)
      end
    end

    def stats_to_table(first_cell, stats)
      [
        first_cell,
        stats.count,
        stats.total_size,
        stats.min_size,
        stats.quartile_1_size,
        stats.median_size,
        stats.quartile_3_size,
        stats.max_size
      ]
    end

    # Finds and returns mailboxes based on mailbox names.
    def find_mailboxes(names)
      if names && names.length > 0
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
    #
    # Options:
    # * +:depth+ maximum depth of recursion
    def determine_max_level(mailbox, options = {})
      if mailbox.is_root?
        options[:depth]
      else
        depth = options[:depth] || 0
        depth >= 0 ? mailbox.level + depth : nil
      end
    end

    def sorted_list(list, options = {})
      sorted = case options[:sort]
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
      when nil
        list
      else
        raise "invalid sort option: #{options[:sort]}"
      end
      options[:sort_order] == :desc ? sorted.reverse : sorted
    end

  end
end
