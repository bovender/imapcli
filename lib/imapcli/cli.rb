# frozen_string_literal: true

module Imapcli
  class Cli # rubocop:disable Metrics/ClassLength,Style/Documentation
    extend GLI::App

    program_desc 'Command-line interface for IMAP servers'

    version Imapcli::VERSION

    subcommand_option_handling :normal
    arguments :strict
    sort_help :manually
    wrap_help_text :tty_only

    desc 'Domain name (FQDN) of the IMAP server'
    default_value ENV.fetch('IMAP_SERVER', nil)
    arg_name 'imap.example.com'
    flag %i[s server]

    desc 'Log-in name (username/email)'
    default_value ENV.fetch('IMAP_USER', nil)
    arg_name 'user'
    flag %i[u user]

    desc 'Log-in password'
    # default_value ENV['IMAP_PASS']
    arg_name 'password'
    flag %i[p password]

    desc 'Prompt for password'
    switch %i[P prompt], negatable: false

    desc 'Verbose output (e.g., response values from Rubys Net::IMAP)'
    switch %i[v verbose], negatable: false

    desc 'Tests if the server is available and log-in succeeds with the credentials'
    command :check do |c|
      c.action do |_global_options, _options, _args|
        @command.check ? @prompt.ok('login successful') : @prompt.error('login failed')
      end
    end

    desc 'Prints information about the server'
    command :info do |c|
      c.action do |_global_options, _options, _args|
        @command.info.each { |line| @prompt.say line }
      end
    end

    desc 'Lists mailboxes (folders)'
    command :list do |c|
      c.action do |_global_options, _options, _args|
        @command.list.each { |line| @prompt.say line }
      end
    end

    desc 'Collects mailbox statistics'
    arg_name :mailbox, optional: true, multiple: true
    command :stats do |c| # rubocop:disable Metrics/BlockLength
      c.switch %i[r recurse],
        desc: 'Recurse into sub mailboxes',
        negatable: false
      c.switch %i[R no_recurse],
        desc: 'Do not recurse into sub mailboxes',
        negatable: false
      c.switch %i[H human],
        desc: 'Convert byte counts to human-friendly formats',
        negatable: false
      c.flag %i[o sort],
        desc: 'Ordered (sorted) results',
        arg_name: 'sort_property',
        must_match: %w[count total_size median_size min_size q1_size q3_size max_size],
        default: 'total_size'
      c.switch %i[reverse], desc: 'Reverse sort order (largest first)', negatable: false
      c.switch [:csv], desc: 'Output comma-separated values (CSV)'
      c.flag %i[l limit],
        desc: 'Limit the results to n folders (IMAP mailboxes)',
        arg_name: 'max_lines',
        default: 10

      c.action do |_global_options, options, args| # rubocop:disable Metrics/BlockLength
        raise unless @validator.stats_options_valid?(options, args)

        progress_bar = nil

        head = ['Mailbox', 'Count', 'Total size', 'Min', 'Q1', 'Median', 'Q3', 'Max']
        body = @command.stats(args, options) do |n|
          if progress_bar
            progress_bar.advance
          else
            @prompt.say "info: collecting stats for #{n} folders" if n > 1
            progress_bar = TTY::ProgressBar.new(
              'collecting stats... :current/:total (:percent, :eta remaining)',
              total: n, clear: true
            )
          end
        end
        formatted_body = body.map do |row|
          row[0..1] + row[2..].map { |cell| format_bytes(cell, options[:human]) }
        end

        if options[:csv]
          unless options[:human]
            @prompt.warn 'notice: BREAKING CHANGE IN VERSION 2: messages sizes in CSV output are now given in bytes, not kiB'
          end
          @prompt.say head.to_csv
          last_mailbox_line = body.length == 1 ? -1 : -2 # skip grand total if present
          formatted_body[0..last_mailbox_line].each { |row| @prompt.say row.to_csv }
        else
          formatted_body = formatted_body.insert(0, :separator).insert(-2, :separator)

          if options[:human]
            @prompt.say "notice: -H/--human flag present, message sizes are given with SI prefixes"
          else
            @prompt.say "notice: message sizes are given in bytes"
          end

          table = TTY::Table.new(head, formatted_body)
          rendered_table = table.render(:unicode) do |renderer|
            renderer.alignments =  [:left] + Array.new(7, :right)
            renderer.border.style = :blue
          end
          @prompt.say rendered_table

          # If any unknown mailboxes were requested, print an informative footer
          if body.any? { |line| line[0].start_with? Imapcli::Command.unknown_mailbox_prefix }
            @prompt.warn "#{Imapcli::Command.unknown_mailbox_prefix}unknown mailbox"
          end
        end
      end
    end

    def self.format_bytes(bytes, human = false)
      human ? ActiveSupport::NumberHelper.number_to_human_size(bytes) : bytes
    end

    pre do |global, _command, _options, _args|
      @prompt = TTY::Prompt.new
      @validator = Imapcli::OptionValidator.new
      raise unless @validator.global_options_valid?(global)

      global[:p] = @prompt.mask 'Enter password:' if global[:P]
      global[:p] ||= ENV.fetch('IMAP_PASS', nil)

      client = Imapcli::Client.new(global[:s], global[:u], global[:p])
      @prompt.say "server: #{global[:s]}"
      @prompt.say "user: #{global[:u]}"
      raise 'invalid server name' unless client.server_valid?
      raise 'invalid user name' unless client.user_valid?

      @prompt.warn 'warning: no password was provided (missing -p/-P option)' unless global[:p]
      raise 'unable to connect to server' unless client.connection

      @command = Imapcli::Command.new(client)

      true
    end

    post do |global, _command, _options, _args|
      @client&.logout
      if global[:v]
        @prompt.say "\n>>> --verbose switch on, listing server responses <<<"
        @client.responses.each do |response|
          @prompt.say response
        end
      end
    end

    on_error do |exception|
      @client&.logout
      if @validator&.errors&.any?
        @validator.errors.each { |error| @prompt.error error }
      else
        @prompt&.error "error: #{exception}"
      end
      @prompt.nil? # if we do not have a prompt yet, let GLI handle the exception
    end

    def print_warnings
      @validator.warnings.each { |warning| @prompt.warn warning }
    end
  end
end
