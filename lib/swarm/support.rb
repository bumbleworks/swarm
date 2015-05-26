require "securerandom"

module Swarm
  module Support
    class << self
      def deep_merge(hsh1, hsh2)
        hsh1.merge(hsh2) { |key, v1, v2|
          if [v1, v2].all? { |v| v.is_a?(Array) }
            v1 | v2
          elsif [v1, v2].all? { |v| v.is_a?(Hash) }
            deep_merge(v1, v2)
          else
            v2
          end
        }
      end

      def symbolize_keys!(hsh)
        hsh.keys.each do |key|
          hsh[key.to_sym] = hsh.delete(key)
        end
      end

      def uuid_with_timestamp
        "#{Time.now.strftime("%Y%m%d-%H%M%S")}-#{SecureRandom.uuid}"
      end

      def camelize(string)
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }
        string = string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
      end

      def constantize(string)
        name_parts = camelize(string).split('::')
        name_parts.shift if name_parts.first.empty?
        constant = Object

        name_parts.each do |name_part|
          const_defined_args = [name_part]
          const_defined_args << false unless Module.method(:const_defined?).arity == 1
          constant_defined = constant.const_defined?(*const_defined_args)
          constant = constant_defined ? constant.const_get(name_part) : constant.const_missing(name_part)
        end
        constant
      end
    end
  end
end