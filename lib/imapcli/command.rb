# frozen_string_literal: true

module Imapcli
  # Provides entry points for Imapcli.
  #
  # Most of the methods in this class return
  class Command # rubocop:disable Metrics/ClassLength
    def initialize(client)
      raise ArgumentError, 'Imapcli::Client is required' unless client.is_a?(Imapcli::Client)

      @client = client
    end

    # Checks if the server accepts the login with the given credentials.
    #
    # Returns true if successful, false if not.
    def check
      @client.login
    end

    # Collects basic information about the server.
    def info # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      perform do
        output = []
        output << "greeting: #{@client.greeting}"
        output << "capability: #{@client.capability.join(' ')}"
        output << "hierarchy separator: #{@client.separator}"
        if @client.supports_quota
          usage = ActiveSupport::NumberHelper.number_to_human_size(@client.quota[0])
          available = ActiveSupport::NumberHelper.number_to_human_size(@client.quota[1])
          output << "quota: #{usage} used, #{available} available (#{@client.quota[2].round(1)}%)"
        else
          output << 'quota: IMAP QUOTA extension not supported by this server'
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
    def stats(mailbox_names = [], options = {}) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      mailbox_names = [mailbox_names] unless mailbox_names.is_a? Array
      perform do
        # Map the command line arguments to Imapcli::Mailbox objects
        mailboxes = find_mailboxes(mailbox_names)
        list = mailboxes.inject([]) do |ary, mailbox|
          ary + mailbox.to_list(determine_max_level(mailbox, options))
        end
        raise 'mailbox not found' unless list.count.positive?

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

        output = if options[:limit]
          sorted_list(list, options).last(options[:limit].to_i)
        else
          sorted_list(list, options)
        end.map do |mailbox|
          stats_to_table(mailbox.full_name, mailbox.stats)
        end
        output << stats_to_table('Total', total_stats) if list.length > 1
        output
      end
    end

    def self.unknown_mailbox_prefix
      '!!! '
    end

    private

    def perform
      raise 'unable to log into server' unless @client.login

      yield
    end

    def traverse_mailbox_tree(mailbox, depth = 0)
      this = mailbox.imap_mailbox? ? ["#{'  ' * [depth - 1, 0].max}- #{mailbox.name}"] : []
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
        stats.max_size,
      ]
    end

    # Finds and returns mailboxes based on mailbox names.
    def find_mailboxes(names)
      if names&.length&.positive?
        Imapcli::Mailbox.consolidate(
          names.filter_map { |name| @client.find_mailbox(name) }
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
      if mailbox.root?
        options[:depth]
      else
        depth = options[:depth] || 0
        depth >= 0 ? mailbox.level + depth : nil
      end
    end

    def sorted_list(list, options)
      return list if options.nil? || options[:sort].nil?
      sort_property = options[:sort]&.to_sym
      if %i[count total_size min_size q1 median_size q3 max_size].include? sort_property
        sorted = sort_mailboxes(list, sort_property, options[:reverse])
      else
        raise "invalid sort option: #{options[:sort]}"
      end
    end

    private
    
    # Sorts a list of mailboxes according to a given property
    # such as total count of e-mails, total size of all e-mails etc.
    # Some mailboxes may not have this property, e.g., an empty
    # mailbox will have `nil` values for median_size etc.
    # We always sort mailboxes with `nil` values to the bottom.
    def sort_mailboxes(mailboxes, property, reverse)
      # Devide ary into two parts, one part where the property has a value
      # and the other where the property is nil.
      partitions = mailboxes.partition { |mailbox| mailbox.stats.send(property) }
      sorted = partitions[0].sort_by { |mailbox| mailbox.stats.send(property) }
      sorted = sorted.reverse if reverse
      sorted + partitions[1]
    end

  end
end
