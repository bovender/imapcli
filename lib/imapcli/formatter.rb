require 'tty-prompt'
require 'tty-table'

module Imapcli
  # Helper class that formats output.
  class Formatter
    # Holds an instance of TTY::Prompt.
    attr_reader :prompt

    def initialize(prompt = nil)
      @prompt = prompt || TTY::Prompt.new
    end

    # Prints a header line for mailbox stats.
    def mailbox_stats_header
      [ 'Mailbox', 'Count', 'Size', 'Min', 'Q1', 'Median', 'Q3', 'Max' ]
    end

    # Prints mailbox stats.
    #
    # +stats+ is a hash as returned by +Imapcli::Client#examine+.
    def mailbox_stats(mailbox)
      return unless mailbox&.stats
      rows = [[
        mailbox.name,
        mailbox.stats[:count],
        format_kib(mailbox.stats[:size]),
        format_kib(mailbox.stats[:min]),
        format_kib(mailbox.stats[:q1]),
        format_kib(mailbox.stats[:median]),
        format_kib(mailbox.stats[:q3]),
        format_kib(mailbox.stats[:max])
      ]]
      print_table(mailbox_stats_header, rows)
    end

    private

    # Performs actual output
    def print(content)
      @prompt.say content
    end

    # Prints a TTY::Table.
    def print_table(header, rows)
      table = TTY::Table.new(header, rows)
      @prompt.say table.render(:unicode, alignments: [:left] + Array.new(5, :right) )
    end

    def format_kib(kib)
      kib.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse + ' kiB'.freeze
    end

  end
end
