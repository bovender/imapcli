# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Imapcli::Stats do
  let(:array) { (1..12).map { |i| i * 1024 } }
  let(:other_array) { (13..24).map { |i| i * 1024 } }
  let(:stats) { described_class.new(array) }
  let(:other_stats) { described_class.new(other_array) }

  it 'knows the number of items' do
    expect(stats.count).to eq 12
  end

  it 'computes the minimum' do
    expect(stats.min_size).to eq 1
  end

  it 'computes the maximum' do
    expect(stats.max_size).to eq 12
  end

  it 'computes the median' do
    expect(stats.median_size).to eq 7 # response is rounded
  end

  it 'computes the first quartile' do
    expect(stats.quartile_1_size).to eq 4 # response is rounded
  end

  it 'computes the third quartile' do
    expect(stats.quartile_3_size).to eq 9 # response is rounded
  end

  it 'adds nothing if other stats are nil' do
    expect { stats.add nil }.to_not raise_error
  end

  context 'when adding other stats' do
    before do
      stats.add other_stats
    end

    it 'can add other stats' do
      expect(stats.count).to eq 24
    end

    it 'computes the minimum' do
      expect(stats.min_size).to eq 1
    end

    it 'computes the maximum' do
      expect(stats.max_size).to eq 24
    end

    it 'computes the median' do
      expect(stats.median_size).to eq 13 # response is rounded
    end

    it 'computes the first quartile' do
      expect(stats.quartile_1_size).to eq 7 # response is rounded
    end

    it 'computes the third quartile' do
      expect(stats.quartile_3_size).to eq 18 # response is rounded
    end

  end

end
