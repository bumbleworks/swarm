# frozen_string_literal: true

require_relative "parser"
require_relative "transformer"

module Swarm
  module Pollen
    class Reader
      def initialize(pollen)
        @pollen = pollen
      end

      def to_hash
        Transformer.new.apply(
          Parser.new.parse(@pollen, reporter: Parslet::ErrorReporter::Deepest.new)
        )
      end

      def to_json(*_args)
        to_hash.to_json
      end
    end
  end
end
