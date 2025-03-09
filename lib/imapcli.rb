# frozen_string_literal: true

# require ruby dependencies
require 'csv'
require 'net/imap'
# require 'pp'

# require external dependencies
# require 'pry'
require 'descriptive_statistics'
require 'filesize'
require 'gli'
require 'dotenv'
require 'tty-prompt'
require 'tty-table'
require 'tty-progressbar'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.setup
end

module Imapcli # rubocop:disable Style/Documentation
end
