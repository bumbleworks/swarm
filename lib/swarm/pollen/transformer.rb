# frozen_string_literal: true

require "parslet"

module Swarm
  module Pollen
    class Transformer < Parslet::Transform
      class << self
        def transform_arguments(args)
          if args.is_a?(Array) && !args.empty?
            args.reduce(:merge)
          else
            args
          end
        end
      end

      rule(symbol: simple(:sym)) do sym.to_s end
      rule(token: simple(:token)) do token.to_s end
      rule(string: simple(:st)) do st.to_s end
      rule(line: simple(:line)) do line.to_s end
      rule(float: simple(:float)) do float.to_f end
      rule(integer: simple(:int)) do int.to_i end

      rule(key: simple(:key), value: simple(:value)) do
        { key => value }
      end
      rule(conditional: simple(:conditional), conditional_clause: simple(:clause), true_tree: subtree(:true_tree),
           false_tree: subtree(:false_tree)) do
        [conditional.to_s, { "condition" => clause }, {
          "true" => [
            ["sequence", {}, true_tree]
          ],
          "false" => [
            ["sequence", {}, false_tree]
          ]
        }]
      end

      rule(conditional: simple(:conditional), conditional_clause: simple(:clause), true_tree: subtree(:true_tree)) do
        [conditional.to_s, { "condition" => clause }, {
          "true" => [
            ["sequence", {}, true_tree]
          ]
        }]
      end

      rule(command: simple(:command)) do
        [command.to_s, {}, []]
      end
      rule(command: simple(:command), tree: subtree(:tree)) do
        [command.to_s, {}, tree]
      end
      rule(command: simple(:command), arguments: subtree(:args)) do |captures|
        [captures[:command].to_s, transform_arguments(captures[:args]), []]
      end
      rule(command: simple(:command), text_argument: simple(:ta), arguments: subtree(:args)) do |captures|
        [captures[:command].to_s, { "text" => captures[:ta] }.merge(transform_arguments(captures[:args])), []]
      end
      rule(command: simple(:command), arguments: subtree(:args), tree: subtree(:tree)) do |captures|
        [captures[:command].to_s, transform_arguments(captures[:args]), captures[:tree]]
      end
      rule(command: simple(:command), text_argument: simple(:ta)) do
        [command.to_s, { "text" => ta }, []]
      end
      rule(metadata: subtree(:metadata), tree: subtree(:tree)) { |captures|
        metadata = (captures[:metadata] || {}).reduce(:merge)
        (metadata || {}).merge("definition" => captures[:tree])
      }
    end
  end
end
