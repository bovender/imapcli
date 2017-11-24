require 'imapcli'

RSpec.describe Imapcli::Command do

  context 'without a client' do
    it 'cannot be instantiated' do
      expect { Imapcli::Command.new('foobar') }.to raise_error(ArgumentError)
    end
  end

  context 'with a mock client' do
    let(:client) do
      client = Imapcli::Client.new('server', 'user', 'pass')
      allow(client).to receive(:login).and_return(true)
      client
    end
    let(:command) { Imapcli::Command.new(client) }
    let(:mailbox_root) do
      Imapcli::Mailbox.new([
        Net::IMAP::MailboxList.new(nil, '/', 'Inbox'),
        Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Foo'),
        Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Foo/Sub'),
        Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar'),
        Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar/Sub'),
        Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar/Sub/Subsub'),
      ])
    end

    it 'can be instantiated' do
      expect { Imapcli::Command.new(client) }.to_not raise_error
    end

    it 'can log in' do
      expect(command.check).to eq true
    end

    it 'can collect information about the server' do
      allow(client).to receive(:greeting).and_return 'hello'
      allow(client).to receive(:capability).and_return ['lots', 'of', 'capabilities']
      allow(client).to receive(:separator).and_return '/'
      allow(client).to receive(:supports_quota).and_return true
      allow(client).to receive(:quota).and_return [ '1024', '2048', 50.00 ]
      output = command.info
      expect(output).to be_a Array
      expect(output[0]).to eq 'greeting: hello'
    end

    it 'can list mailboxes' do
      allow(client).to receive(:mailbox_root).and_return mailbox_root
      output = command.list
      expect(output).to be_a Array
      expect(output[0]).to eq '- Inbox'
    end


  end
end
