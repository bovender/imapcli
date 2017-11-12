module Imapcli
  # In IMAP speak, a mailbox is what one would commonly call a 'folder'
  class Mailbox
    attr_reader :children, :imap_mailbox_list, :name

    def initialize(name, imap_mailbox_lists = nil)
      @name = name || ''
      @children = {}
      if imap_mailbox_lists
        imap_mailbox_lists.sort_by { |m| m.name.downcase }.each { |i| add_mailbox i }
      end
    end

    def [](mailbox)
      @children[mailbox]
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

    # Adds a sub mailbox designated by the +name+ of a Net::IMAP::MailboxList.
    def add_mailbox(imap_mailbox_list)
      return unless imap_mailbox_list&.name&.length > 0
      recursive_add(imap_mailbox_list, imap_mailbox_list.name)
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

    # Collects statistics for this mailbox and all of its children
    #
    # +connection+ must be a Net::IMAP object
    def collect_stats(connection)
      if full_name # proceed only if this is a mailbox of its own
        stats = connection.examine(full_name)
        
      end
      @children.values.each { |child| child.collect_stats(connection) }
    end

    protected

    def recursive_add(imap_mailbox_list, relative_name = nil)
      delimiter = imap_mailbox_list.delim
      if relative_name
        sub_mailbox_name, subs_subs = relative_name.split(delimiter, 2)
        if @children[sub_mailbox_name]
          sub_mailbox = @children[sub_mailbox_name]
        else
          sub_mailbox = Mailbox.new(sub_mailbox_name)
          @children[sub_mailbox_name] = sub_mailbox
        end
        sub_mailbox.recursive_add(imap_mailbox_list, subs_subs)
      else # no more sub mailboxes: we've reached the last of the children
        @imap_mailbox_list = imap_mailbox_list
        self
      end
    end
  end
end
