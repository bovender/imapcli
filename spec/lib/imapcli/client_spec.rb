# frozen_string_literal: true

require 'imapcli'
require 'dotenv'

RSpec.describe Imapcli::Client do

  context 'with mock credentials for a nonexistent server' do
    let(:client) { described_class.new('imap.example.com', 'username', 'password') }

    it 'knows when a server name is invalid' do
      client.server = 'i n v a l i d'
      expect(client.server_valid?).to be false
    end

    it 'knows when a server name is valid' do
      client.server = 'imap.gmail.com'
      expect(client.server_valid?).to be true
    end

    it 'knows when a user name is invalid' do
      client.user = ''
      expect(client.user_valid?).to be false
    end

    it 'knows when a user name is valid' do
      client.user = 'bovender@example.com'
      expect(client.user_valid?).to be true
    end

    it 'uses port 993 by default' do
      expect(client.port).to eq 993
    end

    it 'extracts a port from the server info' do
      client.server = 'imap.example.com:143'
      expect(client.port).to eq 143
    end

    it 'extracts a server from the server string when a port is appended' do
      client.server = 'imap.example.com:143'
      expect(client.server).to eq 'imap.example.com'
    end
  end

  context 'with valid credentials for an actual server', :network do
    before { Dotenv.load }

    let(:client) do
      described_class.new(ENV.fetch('IMAP_SERVER', nil), ENV.fetch('IMAP_USER', nil), ENV.fetch('IMAP_PASS', nil))
    end

    it 'the IMAP_SERVER variable must be set' do
      expect(ENV.fetch('IMAP_SERVER', nil)).to_not be_nil
    end

    it 'the IMAP_USER variable must be set' do
      expect(ENV.fetch('IMAP_USER', nil)).to_not be_nil
    end

    it 'the IMAP_PASS variable must be set' do
      expect(ENV.fetch('IMAP_PASS', nil)).to_not be_nil
    end

    it 'successfully logs in to the server' do
      expect(client.login).to be true
    end
  end

  context 'with invalid credentials for an actual server', :network do
    before { Dotenv.load }

    let(:client) do
      described_class.new(ENV.fetch('IMAP_SERVER', nil), ENV.fetch('IMAP_USER', nil),
                          "#{ENV.fetch('IMAP_PASS', nil)}invalid")
    end

    it 'cannot log in to the server' do
      expect(client.login).to be false
    end
  end

end
