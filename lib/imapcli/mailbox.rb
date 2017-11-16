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

    # Counts all sub mailboxes recursively
    def count_sub_mailboxes
      @children.values.inject(@children.length) do |count, child|
        count += child.count_sub_mailboxes
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

    # Collects statistics for this mailbox.
    #
    # +connection+ must be a Net::IMAP object
    def collect_stats(client)
      if full_name # proceed only if this is a mailbox of its own
        @stats = Stats.new(client.message_sizes(full_name))
      end
    end

    # Collects statistics for this mailbox and all of its children.
    #
    # +connection+ must be a Net::IMAP object
    def collect_stats_recursively(connection)
      collect_stats(connection)
      @children.values.each { |child| child.collect_stats_recursively(connection) }
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
