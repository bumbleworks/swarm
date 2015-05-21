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

      def uuid_with_timestamp
        "#{Time.now.strftime("%Y%m%d-%H%M%S")}-#{SecureRandom.uuid}"
      end

      def camelize(string)
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }
        string = string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
      end

      def constantize(string)
        camelized = camelize(string)
        camelized.split('::').inject(Object) { |scope, const|
          scope.const_get(const)
        }
      end
    end
  end
end