require "parslet"

module Swarm
  module Pollen
    class Parser < Parslet::Parser
      def optionally_spaced(atom)
        spaces? >> atom >> spaces?
      end

      rule(:eol) { (optionally_spaced(match['\n'])).repeat(1) }
      rule(:whitespace) { match('\s').repeat(0) }
      rule(:spaces) { match[' \t'].repeat(1) }
      rule(:spaces?) { spaces.maybe }
      rule(:comma) { optionally_spaced(str(',')) }

      rule(:integer) {
        match['0-9'].repeat(1).as(:integer)
      }

      rule(:float) {
        (match['0-9'].repeat(1) >> str('.') >> match['0-9'].repeat(1)).as(:float)
      }

      rule(:line) {
        (match['\n'].absent? >> any).repeat(1).as(:line)
      }

      rule(:string) {
        (str("'") | str('"')).capture(:q) >>
          (str('\\') >> any |
            dynamic { |s,c| str(c.captures[:q]) }.absent? >> any
          ).repeat.as(:string) >> dynamic { |s,c| str(c.captures[:q]) }
      }

      rule(:colon_pair) {
        token.as(:key) >> str(':') >> spaces? >> string.as(:value)
      }

      rule(:symbol) { str(':') >> token.as(:symbol) }
      rule(:token) { (match('[a-z_]') >> match('[a-zA-Z0-9_]').repeat(0)).as(:token) }

      rule(:rocket_pair) {
        (symbol | string).as(:key) >> optionally_spaced(str('=>')) >> string.as(:value)
      }

      rule(:key_value_pair) { rocket_pair | colon_pair }

      rule(:key_value_list) {
        key_value_pair >> (comma >> key_value_pair).repeat(0)
      }

      rule(:arguments) {
        key_value_list.as(:arguments) | string.as(:text_argument)
      }

      rule(:reserved_word) {
        %w(if unless else end).map { |w| str(w) }.reduce(:|)
      }

      rule(:expression) {
        reserved_word.absent? >> token.as(:command) >> (spaces >> arguments).maybe
      }

      rule(:tree) {
        ((conditional_block | branch_block | expression) >> eol).repeat(0)
      }

      rule(:conditional_block) {
        (str('if') | str('unless')).as(:conditional) >>
          spaces >> string.as(:conditional_clause) >> eol >>
          tree.as(:true_tree) >>
          (str('else') >> eol >> tree.as(:false_tree)).maybe >>
        str('end')
      }

      rule(:branch_block) {
        expression >> spaces >> str('do') >> eol >>
          tree.as(:tree) >>
          str('end')
      }

      rule(:metadata_entry) {
        token.as(:key) >> str(':') >> spaces? >>
          (string | float | integer | line).as(:value)
      }

      rule(:metadata) {
        str('---') >> eol >> (metadata_entry >> eol).repeat(0) >> str('---') >> eol
      }

      rule(:document) { whitespace >> metadata.maybe.as(:metadata) >> branch_block.as(:tree) >> whitespace }
      root(:document)
    end
  end
end
