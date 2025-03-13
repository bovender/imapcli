# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Imapcli::Command do

  context 'without a client' do
    it 'cannot be instantiated' do
      expect { described_class.new('foobar') }.to raise_error(ArgumentError)
    end
  end

  context 'with a mock client' do
    let(:client) do
      client = Imapcli::Client.new('server', 'user', 'pass')
      allow(client).to receive(:login).and_return(true)
      client
    end
    let(:command) { described_class.new(client) }
    let(:mailbox_root) do
      Imapcli::Mailbox.new([
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Foo'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Foo/Sub'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Many/Messages'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Bar'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Largest/Messages'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Smallest/Messages'),
                             Net::IMAP::MailboxList.new(nil, '/', 'Inbox/Empty'),
                           ])
    end

    it 'can be instantiated' do
      expect { described_class.new(client) }.to_not raise_error
    end

    it 'logs in' do
      expect(command.check).to be true
    end

    it 'collects information about the server' do
      allow(client).to receive_messages(greeting: 'hello', capability: %w[lots of capabilities], separator: '/',
                                        supports_quota: true, quota: ['1024', '2048', 50.00])
      output = command.info
      expect(output).to be_a Array
      expect(output[0]).to eq 'greeting: hello'
    end

    it 'lists mailboxes' do
      allow(client).to receive(:mailbox_root).and_return mailbox_root
      output = command.list
      expect(output).to be_a Array
      expect(output[0]).to eq '- Inbox'
    end

    context 'when collecting statistics' do
      before do
        allow(client).to receive_messages(mailbox_root: mailbox_root, separator: '/')
        allow(client).to receive(:message_sizes) do |mailbox|
          case mailbox
          when 'Inbox'
            [200, 300, 400, 500]
          when 'Inbox/Foo'
            [355, 360, 380, 200]
          when 'Inbox/Many/Messages'
            Array.new(10, 100)
          when 'Inbox/Bar'
            [2_000, 3_000, 4_000]
          when 'Inbox/Largest/Messages'
            [2_500_000, 100_000, 200_000]
          when 'Inbox/Smallest/Messages'
            [10, 20, 30]
          when 'Inbox/Empty'
            []
          else
            [1024, 2048, 4096, 8192]
          end
        end
      end

      it 'for all folders' do
        output = command.stats
        expect(output).to be_a Array
        expect(output.length).to eq 9
        expect(output[0][0]).to eq 'Inbox' # sorted before 'Inbox'
        expect(output[0][1]).to eq 4
      end

      it 'for a given folder' do
        output = command.stats('Inbox/Foo')
        expect(output).to be_a Array
        expect(output.length).to eq 1
        expect(output[0][0]).to eq 'Inbox/Foo'
        expect(output[0][1]).to eq 4 # depends on message_sizes stub (see above)
      end

      it 'for an empty folder' do
        output = command.stats('Inbox/Empty')
        expect(output).to be_a Array
        expect(output.length).to eq 1
        expect(output[0][0]).to eq 'Inbox/Empty'
        expect(output[0][1]).to eq 0
      end

      it 'for a given folder and subfolders' do
        output = command.stats('Inbox/Foo', depth: -1)
        expect(output).to be_a Array
        expect(output.length).to eq 3
        expect(output[1][0]).to eq 'Inbox/Foo/Sub'
      end

      it 'sorts by number of messages' do
        output = command.stats('Inbox', depth: -1, sort: :count, reverse: true)
        expect(output).to be_a Array
        expect(output[0][0]).to eq 'Inbox/Many/Messages'
      end

      it 'sorts by total message size' do
        output = command.stats('Inbox', depth: -1, sort: :total_size, reverse: false)
        expect(output).to be_a Array
        expect(output[-2][0]).to eq 'Inbox/Largest/Messages'
      end

      it 'reverse-sorts largest message first' do
        output = command.stats('Inbox', depth: -1, sort: :max_size, reverse: true)
        expect(output).to be_a Array
        expect(output[0][0]).to eq 'Inbox/Largest/Messages'
        expect(output[-2][0]).to eq 'Inbox/Empty'
      end

      it 'sorts smallest message first' do
        output = command.stats('Inbox', depth: -1, sort: :min_size, reverse: false)
        expect(output).to be_a Array
        expect(output[0][0]).to eq 'Inbox/Smallest/Messages'
      end

      it 'returns only the first n mailboxes' do
        output = command.stats('Inbox', depth: -1, limit: 2)
        expect(output.length).to eq 3 # including summary line
      end
    end

  end
end
