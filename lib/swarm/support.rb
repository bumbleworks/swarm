require "securerandom"

module Swarm
  module Support
    class << self
      def deep_merge(hsh1, hsh2, combine_arrays: :override)
        hsh1.merge(hsh2) { |key, v1, v2|
          if [v1, v2].all? { |v| v.is_a?(Array) }
            combine_arrays(v1, v2, method: combine_arrays)
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
        hsh
      end

      def symbolize_keys(hsh)
        symbolize_keys!(hsh.dup)
      end

      def combine_arrays(v1, v2, method: :concat)
        case method.to_s
        when "uniq"
          v1 | v2
        when "concat"
          v1.concat v2
        when "override"
          v2
        else
          raise ArgumentError, "unknown array combination method: #{method}"
        end
      end

      def uuid_with_timestamp
        "#{Time.now.strftime("%Y%m%d-%H%M%S")}-#{SecureRandom.uuid}"
      end

      def tokenize(string)
        return nil if string.nil?
        string = string.to_s.gsub(/&/, ' and ').
          gsub(/[ \/]+/, '_').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          downcase
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

      def slice(hash, *keys)
        {}.tap { |h|
          keys.each { |k|
            h[k] = hash[k] if hash.has_key?(k)
          }
        }
      end

      def wait_until(timeout: 5, initial_delay: nil)
        sleep(initial_delay) if initial_delay.is_a?(Numeric)
        Timeout::timeout(timeout) do
          sleep 0.05 until yield
        end
      end
    end
  end
end
