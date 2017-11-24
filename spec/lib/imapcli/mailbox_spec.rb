require 'imapcli'
require 'net/imap'

RSpec.describe Imapcli::Mailbox do
  let(:mailbox) do
    Imapcli::Mailbox.new([
      Net::IMAP::MailboxList.new(nil, '/', 'Inbox'),
      Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Foo'),
      Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Foo/Sub'),
      Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar'),
      Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar/Sub'),
      Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar/Sub/Subsub'),
    ])
  end
  # it 'parses a mailbox list' do
  #   mailbox_list = Net::IMAP::MailboxList.new(attr: nil, delim: '/', name: 'Root/Subfolder')
  #   mailbox_root = Imapcli::MailboxTree.new(mailbox_list)
  #   expect(mailbox_root.tree.length).to eq 1
  # end
  it 'returns nil if a given sub mailbox does not exist' do
    expect(mailbox.find_sub_mailbox('INBOX.does.not.exist', '.')).to eq nil
  end
  it 'adds and retrieves an existing sub mailbox' do
    name = 'Root/Subfolder/Subsubfolder'
    imap_mailbox_list = Net::IMAP::MailboxList.new(nil, '/', name)
    mailbox = Imapcli::Mailbox.new
    mailbox.add_mailbox(imap_mailbox_list)
    expect(mailbox.find_sub_mailbox(name, '/').imap_mailbox_list).to eq imap_mailbox_list
  end
  it 'counts the number of mailboxes' do
    expect(mailbox.count).to eq 7 # includes virtual root mailbox
  end
  it 'determines the maximum level in the subtree' do
    expect(mailbox.get_max_level).to eq 3
  end
  it 'converts a tree to a list' do
    list = mailbox.to_list
    list_names = list.map { |m| m.full_name }
    expect(list_names).to eq [
      'Inbox',
      'Inbox/Bar',
      'Inbox/Bar/Sub',
      'Inbox/Bar/Sub/Subsub',
      'Inbox/Foo',
      'Inbox/Foo/Sub',
    ]
  end

  context 'identification and consolidation' do
    let(:parent) { mailbox.find_sub_mailbox('Inbox', '/') }
    let(:child) { mailbox.find_sub_mailbox('Inbox/Bar/Sub/Subsub', '/') }

    it 'knows if it is contains another mailbox' do
      expect(parent.contains? child).to eq true
    end
    it 'knows if it is does not contain another mailbox' do
      expect(child.contains? mailbox).to eq false
    end
    # it 'consolidates several of the same mailboxes' do
    #  expect(Imapcli::Mailbox.consolidate([parent, parent])).to eq [ parent ]
    # end
    it 'consolidates several of the same mailbox' do
     expect(Imapcli::Mailbox.consolidate([child, child])).to eq [ child ]
    end
    it 'consolidates several different mailboxes' do
     expect(Imapcli::Mailbox.consolidate([child, parent])).to eq [ parent ]
    end

  end
end
