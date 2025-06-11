# frozen_string_literal: true

require "parslet"

module Swarm
  module Pollen
    class Parser < Parslet::Parser
      def optionally_spaced(atom)
        spaces? >> atom >> spaces?
      end

      rule(:eol) do optionally_spaced(match['\n']).repeat(1) end
      rule(:whitespace) do match('\s').repeat(0) end
      rule(:spaces) do match[' \t'].repeat(1) end
      rule(:spaces?) do spaces.maybe end
      rule(:comma) do optionally_spaced(str(',')) end

      rule(:integer) do
        match['0-9'].repeat(1).as(:integer)
      end

      rule(:float) do
        (match['0-9'].repeat(1) >> str('.') >> match['0-9'].repeat(1)).as(:float)
      end

      rule(:line) do
        (match['\n'].absent? >> any).repeat(1).as(:line)
      end

      rule(:string) do
        (str("'") | str('"')).capture(:q) >>
          (str('\\') >> any |
            dynamic { |_s, c| str(c.captures[:q]) }.absent? >> any
          ).repeat.as(:string) >> dynamic { |_s, c| str(c.captures[:q]) }
      end

      rule(:colon_pair) do
        token.as(:key) >> str(':') >> spaces? >> string.as(:value)
      end

      rule(:symbol) do str(':') >> token.as(:symbol) end
      rule(:token) do (match('[a-z_]') >> match('[a-zA-Z0-9_]').repeat(0)).as(:token) end

      rule(:rocket_pair) do
        (symbol | string).as(:key) >> optionally_spaced(str('=>')) >> string.as(:value)
      end

      rule(:key_value_pair) do rocket_pair | colon_pair end

      rule(:key_value_list) do
        key_value_pair >> (comma >> key_value_pair).repeat(0)
      end

      rule(:arguments) do
        key_value_list.as(:arguments) | (
          string.as(:text_argument) >> (comma >> key_value_list.as(:arguments)).maybe
        )
      end

      rule(:reserved_word) do
        %w[if unless else end].map { |w| str(w) }.reduce(:|)
      end

      rule(:expression) do
        reserved_word.absent? >> token.as(:command) >> (spaces >> arguments).maybe
      end

      rule(:tree) do
        ((conditional_block | branch_block | expression) >> eol).repeat(0)
      end

      rule(:conditional_block) do
        (str('if') | str('unless')).as(:conditional) >>
          spaces >> string.as(:conditional_clause) >> eol >>
          tree.as(:true_tree) >>
          (str('else') >> eol >> tree.as(:false_tree)).maybe >>
          str('end')
      end

      rule(:branch_block) do
        expression >> spaces >> str('do') >> eol >>
          tree.as(:tree) >>
          str('end')
      end

      rule(:metadata_entry) do
        token.as(:key) >> str(':') >> spaces? >>
          (string | float | integer | line).as(:value)
      end

      rule(:metadata) do
        str('---') >> eol >> (metadata_entry >> eol).repeat(0) >> str('---') >> eol
      end

      rule(:document) do whitespace >> metadata.maybe.as(:metadata) >> branch_block.as(:tree) >> whitespace end
      root(:document)
    end
  end
end
