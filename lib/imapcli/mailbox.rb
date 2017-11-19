module Imapcli
  # In IMAP speak, a mailbox is what one would commonly call a 'folder'
  class Mailbox
    attr_reader :level, :children, :imap_mailbox_list, :name, :stats

    # Creates a new root Mailbox object and optionally adds sub mailboxes from
    # an array of Net::IMAP::MailboxList items.
    def initialize(mailbox_list_items = nil)
      @level = 0
      @children = {}
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

    # Counts all sub mailboxes recursively.
    #
    # The result does not include the current mailbox.
    def count_sub_mailboxes
      @children.values.inject(@children.length) do |count, child|
        count += child.count_sub_mailboxes
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
    def add_mailbox(imap_mailbox_list, options = {})
      return unless imap_mailbox_list&.name&.length > 0
      recursive_add(0, imap_mailbox_list, imap_mailbox_list.name, options)
    end

    # Attempts to locate and retrieve a sub mailbox.
    #
    # Returns nil of none exists with the given name.
    # Name must be relative to the current mailbox.
    def find_sub_mailbox(relative_name, delimiter)
      if relative_name
        sub_mailbox_name, subs_subs = relative_name.split(delimiter, 2)
        if sub_mailbox = @children[sub_mailbox_name]
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
    # If a block is given, it is called with the Imapcli::Stats object for this
    # mailbox.
    def collect_stats(client, max_level = nil)
      if full_name # proceed only if this is a mailbox of its own
        @stats = Stats.new(client.message_sizes(full_name))
      end
      yield @stats if block_given?
      if max_level && level < max_level
        @children.values.each { |child| child.collect_stats(client, max_level) }
      end
    end

    # Converts the mailbox tree to a flat list.
    #
    # Mailbox objects that do not represent IMAP mailboxes (such as the root
    # mailbox) are not included.
    def to_list
      list = @children.values.inject([self]) do |ary, child|
        ary + child.to_list
      end
      list.select { |e| e.is_imap_mailbox? }.sort_by { |e| e.full_name }
    end

    protected

    def level=(level)
      @level = level
    end

    def name=(name)
      @name = name
    end

    def recursive_add(level, imap_mailbox_list, relative_name = nil, options = {})
      delimiter = options[:delimiter] || imap_mailbox_list.delim
      if relative_name
        sub_mailbox_name, subs_subs = relative_name.split(delimiter, 2)
        if options[:case_insensitive] || (level == 0 && relative_name.upcase == 'INBOX')
          key = sub_mailbox_name.upcase
        else
          key = sub_mailbox_name
        end
        # Create a new mailbox if there does not exist one by the name
        unless sub_mailbox = @children[key]
          sub_mailbox = Mailbox.new
          sub_mailbox.level = level
          sub_mailbox.name = sub_mailbox_name
          @children[key] = sub_mailbox
        end
        sub_mailbox.recursive_add(level + 1, imap_mailbox_list, subs_subs, options)
      else # no more sub mailboxes: we've reached the last of the children
        @imap_mailbox_list = imap_mailbox_list
        self
      end
    end

  end
end
