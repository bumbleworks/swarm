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

      rule(:symbol => simple(:sym)) { sym.to_s }
      rule(:token => simple(:token)) { token.to_s }
      rule(:string => simple(:st)) { st.to_s }
      rule(:line => simple(:line)) { line.to_s }
      rule(:float => simple(:float)) { float.to_f }
      rule(:integer => simple(:int)) { int.to_i }

      rule(:key => simple(:key), :value => simple(:value)) {
        { key => value }
      }
      rule(:conditional => simple(:conditional), :conditional_clause => simple(:clause), :true_tree => subtree(:true_tree), :false_tree => subtree(:false_tree)) {
        [conditional.to_s, { "condition" => clause }, {
          "true" => [
            ["sequence", {}, true_tree]
          ],
          "false" => [
            ["sequence", {}, false_tree]
          ],
        }]
      }

      rule(:conditional => simple(:conditional), :conditional_clause => simple(:clause), :true_tree => subtree(:true_tree)) {
        [conditional.to_s, { "condition" => clause }, {
          "true" => [
            ["sequence", {}, true_tree]
          ]
        }]
      }

      rule(:command => simple(:command), :tree => subtree(:tree)) {
        [command.to_s, {}, tree]
      }
      rule(:command => simple(:command), :arguments => subtree(:args)) { |captures|
        [captures[:command].to_s, transform_arguments(captures[:args]), []]
      }
      rule(:command => simple(:command), :arguments => subtree(:args), :tree => subtree(:tree)) { |captures|
        [captures[:command].to_s, transform_arguments(captures[:args]), captures[:tree]]
      }
      rule(:command => simple(:command), :text_argument => simple(:ta)) {
        [command.to_s, { "text" => ta }, []]
      }
      rule(:metadata => subtree(:metadata), :tree => subtree(:tree)) { |captures|
        metadata = (captures[:metadata] || {}).reduce(:merge)
        (metadata || {}).merge("definition" => captures[:tree])
      }
    end
  end
end
