# frozen_string_literal: true

module Imapcli
  # Utility class to validate user options
  #
  # Invalid options will trigger a runtime exception (which is handled by GLI).
  class OptionValidator
    attr_reader :errors, :warnings, :options

    def initialize
      @errors = []
      @warnings = []
    end

    def global_options_valid?(global_options)
      if global_options[:s].nil? || global_options[:s].empty?
        @errors << 'missing server name (use -s option or set IMAP_SERVER environment variable)'
      end
      if global_options[:u].nil? || global_options[:u].empty?
        @errors << 'missing user name (use -u option or set IMAP_USER environment variable)'
      end
      if global_options[:P] && global_options[:p]
        @errors << '-p and -P options do not agree'
      end

      pass?
    end

    # Validates options for the stats command.
    #
    # @return [true false] indicating success or failure; warnings can be accessed as attribute
    def stats_options_valid?(options, args)
      @options = {}
      raise 'incompatible options -r/--recurse and -R/--no_recurse' if options[:r] && options[:R]

      if options[:recurse]
        if args.empty?
          @warnings << 'warning: superfluous -r/--recurse option; will recurse from root by default'
        else
          @options[:depth] = -1
        end
      elsif options[:no_recurse]
        if args.empty?
          @options[:depth] = 0
        else
          @warnings << 'warning: superfluous -R/--no_recurse option; will not recurse from non-root mailbox by default'
        end
      end

      if options[:sort]
        available_sort_options = %w(count total_size min_size q1 median_size q3 max_size)
        if available_sort_options.include? options[:sort].downcase
          @options[:sort] = options[:sort].to_sym
        else
          # GLI did not print the available options even with the :must_match option
          @errors << "sort option must be one of: #{available_sort_options.join(', ')}"
        end
      end

      pass?
    end

    def pass?
      @errors.empty?
    end

    def warnings?
      @warnings.count > 0
    end

  end
end
