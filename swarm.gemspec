# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swarm/version'

Gem::Specification.new do |spec|
  spec.name          = "swarm"
  spec.version       = Swarm::VERSION
  spec.authors       = ["Ravi Gadad"]
  spec.email         = ["ravi@renewfund.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{A workflow engine prototype temporary spike work in progress}
  spec.description   = %q{A workflow engine prototype temporary spike work in progress}
  spec.homepage      = "https://github.com/bumbleworks/swarm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "beaneater", "~> 1.0"
  spec.add_dependency "redis"
  spec.add_dependency "parslet"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.7"
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency "pry"
end
