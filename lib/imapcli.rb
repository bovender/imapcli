# frozen_string_literal: true

# require external dependencies
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.setup
end

module Imapcli
end
