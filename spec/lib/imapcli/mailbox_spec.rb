require 'imapcli'
require 'net/imap'

RSpec.describe Imapcli::Mailbox do
  # it 'parses a mailbox list' do
  #   mailbox_list = Net::IMAP::MailboxList.new(attr: nil, delim: '/', name: 'Root/Subfolder')
  #   mailbox_tree = Imapcli::MailboxTree.new(mailbox_list)
  #   expect(mailbox_tree.tree.length).to eq 1
  # end
  it 'returns nil if a given sub mailbox does not exist' do
    mailbox = Imapcli::Mailbox.new
    expect(mailbox.find_sub_mailbox('INBOX.does.not.exist', '.')).to eq nil
  end
  it 'adds and retrieves an existing sub mailbox' do
    name = 'Root/Subfolder/Subsubfolder'
    imap_mailbox_list = Net::IMAP::MailboxList.new(nil, '/', name)
    mailbox = Imapcli::Mailbox.new
    mailbox.add_mailbox(imap_mailbox_list)
    expect(mailbox.find_sub_mailbox(name, '/').imap_mailbox_list).to eq imap_mailbox_list
  end
end
