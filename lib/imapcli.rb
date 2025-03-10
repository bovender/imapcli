# frozen_string_literal: true

require 'active_support'
require 'csv'
require 'descriptive_statistics'
require 'dotenv'
require 'gli'
require 'net/imap'
require 'tty-progressbar'
require 'tty-prompt'
require 'tty-table'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.setup
end

module Imapcli # rubocop:disable Style/Documentation
end
