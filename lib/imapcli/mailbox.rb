# frozen_string_literal: true

module Imapcli
  # In IMAP speak, a mailbox is what one would commonly call a 'folder'
  class Mailbox
    attr_accessor :options
    attr_reader :level, :children, :imap_mailbox_list, :name, :stats

    # Creates a new root Mailbox object and optionally adds sub mailboxes from
    # an array of Net::IMAP::MailboxList items.
    def initialize(mailbox_list_items = nil, options = {})
      @level = 0
      @children = {}
      @options = options
      add_mailbox_list(mailbox_list_items) if mailbox_list_items
    end

    def [](mailbox)
      @children[mailbox]
    end

    # Determines if this mailbox represents a dedicated IMAP mailbox with an
    # associated Net::IMAP::MailboxList structure.
    def is_imap_mailbox?
      not imap_mailbox_list.nil?
    end

    def is_root?
      name.respond_to?(:empty?) ? !!name.empty? : !name
    end

    # Counts all sub mailboxes recursively.
    #
    # The result includes the current mailbox.
    def count(max_level = nil)
      sum = 1
      if max_level.nil? || level < max_level
        @children.values.inject(sum) do |count, child|
          count + child.count(max_level)
        end
      end
    end

    # Determines the maximum level in the mailbox tree
    def get_max_level
      if has_children?
        @children.values.map { |child| child.get_max_level }.max
      else
        level
      end
    end

    def full_name
      imap_mailbox_list&.name
    end

    def has_children?
      @children.length > 0
    end

    def children
      @children.values
    end

    # Add a list of mailboxes as returned by Net::IMAP#list.
    def add_mailbox_list(array_of_mailbox_list_items)
      array_of_mailbox_list_items.sort_by { |m| m.name.downcase }.each { |i| add_mailbox i }
    end

    # Adds a sub mailbox designated by the +name+ of a Net::IMAP::MailboxList.
    def add_mailbox(imap_mailbox_list)
      return unless imap_mailbox_list&.name&.length > 0
      recursive_add(0, imap_mailbox_list, imap_mailbox_list.name)
    end

    # Returns true if this mailbox contains a given other mailbox.
    def contains?(other_mailbox)
      @children.values.any? do |child|
        child == other_mailbox || child.contains?(other_mailbox)
      end
    end

    # Attempts to locate and retrieve a sub mailbox.
    #
    # Returns nil of none exists with the given name.
    # Name must be relative to the current mailbox.
    def find_sub_mailbox(relative_name, delimiter)
      if relative_name
        sub_mailbox_name, subs_subs = relative_name.split(delimiter, 2)
        key = normalize_key(sub_mailbox_name, level)
        if sub_mailbox = @children[key]
          sub_mailbox.find_sub_mailbox(subs_subs, delimiter)
        else
          nil # no matching sub mailbox found, stop searching the tree
        end
      else
        self
      end
    end

    # Collects statistics for this mailbox and the subordinate mailboxes up to
    # a given level.
    #
    # If level is nil, all sub mailboxes are analyzed as well.
    #
    # If a block is given, it is called with the Imapcli::Stats object for this
    # mailbox.
    def collect_stats(client, max_level = nil)
      return if @stats
      if full_name # proceed only if this is a mailbox of its own
        @stats = Stats.new(client.message_sizes(full_name))
      end
      yield @stats if block_given?
      if max_level.nil? || level < max_level
        @children.values.each do |child|
          child.collect_stats(client, max_level) { |child_stats| yield child_stats}
        end
      end
    end

    # Converts the mailbox tree to a flat list.
    #
    # Mailbox objects that do not represent IMAP mailboxes (such as the root
    # mailbox) are not included.
    def to_list(max_level = nil)
      me = is_imap_mailbox? ? [self] : []
      if max_level.nil? || level < max_level
        @children.values.inject(me) do |ary, child|
          ary + child.to_list(max_level)
        end.sort_by { |e| e.full_name }
      else
        me
      end
    end

    # Consolidates a list of mailboxes: If a mailbox is a sub-mailbox of another
    # one, the mailbox is removed from the list.
    #
    # @param [Array] list of mailboxes
    def self.consolidate(list)
      list.reject do |mailbox|
        list.any? { |parent| parent.contains? mailbox }
      end.uniq
    end

    protected

    def level=(level)
      @level = level
    end

    def name=(name)
      @name = name
    end

    def recursive_add(level, imap_mailbox_list, relative_name = nil)
      delimiter = options[:delimiter] || imap_mailbox_list.delim
      if relative_name
        sub_mailbox_name, subs_subs = relative_name.split(delimiter, 2)
        key = normalize_key(sub_mailbox_name, level)
        # Create a new mailbox if there does not exist one by the name
        unless sub_mailbox = @children[key]
          sub_mailbox = Mailbox.new
          sub_mailbox.level = level
          sub_mailbox.name = sub_mailbox_name
          @children[key] = sub_mailbox
        end
        sub_mailbox.recursive_add(level + 1, imap_mailbox_list, subs_subs)
      else # no more sub mailboxes: we've reached the last of the children
        @imap_mailbox_list = imap_mailbox_list
        self
      end
    end

    # Normalizes a mailbox name for use as the key in the children hash.
    def normalize_key(key, level)
      if options[:case_insensitive] || (level == 0 && key.upcase == 'INBOX')
        key.upcase
      else
        key
      end
    end

  end
end
