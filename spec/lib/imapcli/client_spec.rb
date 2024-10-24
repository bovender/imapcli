# frozen_string_literal: true

require 'imapcli'
require 'dotenv'

RSpec.describe Imapcli::Client do

  context 'with mock credentials for a nonexistent server' do
    let(:client) { Imapcli::Client.new('imap.example.com', 'username', 'password') }
    it 'knows when a server name is invalid' do
      client.server = 'i n v a l i d'
      expect(client.server_valid?).to eq false
    end
    it 'knows when a server name is valid' do
      client.server = 'imap.gmail.com'
      expect(client.server_valid?).to eq true
    end
    it 'knows when a user name is invalid' do
      client.user = ''
      expect(client.user_valid?).to eq false
    end
    it 'knows when a user name is valid' do
      client.user = 'bovender@example.com'
      expect(client.user_valid?).to eq true
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

  context 'with valid credentials for an actual server', network: true do
    before :all do
      Dotenv.load
    end

    let(:client) { Imapcli::Client.new(ENV['IMAP_SERVER'], ENV['IMAP_USER'], ENV['IMAP_PASS']) }

    it 'the IMAP_SERVER variable must be set' do
      expect(ENV['IMAP_SERVER']).to_not eq(nil)
    end
    it 'the IMAP_USER variable must be set' do
      expect(ENV['IMAP_USER']).to_not eq(nil)
    end
    it 'the IMAP_PASS variable must be set' do
      expect(ENV['IMAP_PASS']).to_not eq(nil)
    end
    it 'successfully logs in to the server' do
      expect(client.login).to eq true
    end
  end

  context 'with invalid credentials for an actual server', network: true do
    before :all do
      Dotenv.load
    end

    let(:client) { Imapcli::Client.new(ENV['IMAP_SERVER'], ENV['IMAP_USER'], "#{ENV['IMAP_PASS']}invalid") }

    it 'cannot log in to the server' do
      expect(client.login).to eq false
    end
  end

end
