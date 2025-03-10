# frozen_string_literal: true

module Imapcli
  # Handles mailbox statistics.
  #
  # +message_sizes+ is an array of message sizes in bytes.
  class Stats

    def initialize(message_sizes = [])
      @message_sizes = message_sizes
    end

    # Adds other statistics.
    def add(other_stats)
      return unless other_stats

      @message_sizes += other_stats.message_sizes
      invalidate
    end

    def count
      @count ||= @message_sizes&.length
    end

    def total_size
      @total_size ||= @message_sizes.sum
    end

    def min_size
      @min_size ||= @message_sizes.min
    end

    def quartile_1_size
      @quartile_1_size ||= @message_sizes.percentile(25)
    end

    def median_size
      @median_size ||= @message_sizes.median
    end

    def quartile_3_size
      @quartile_3_size ||= @message_sizes.percentile(75)
    end

    def max_size
      @max_size ||= @message_sizes.max
    end

    protected

    attr_accessor :message_sizes

    private

    def invalidate
      @count, @total_size, @min, @max, @q1, @q3, @median = nil # sets others to nil too
    end

  end
end
