# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swarm/version'

Gem::Specification.new do |spec|
  spec.name          = "swarm"
  spec.version       = Swarm::VERSION
  spec.authors       = ["Ravi Gadad"]
  spec.email         = ["ravi@gadad.net"]

  spec.summary       = %q{A Ruby workflow engine}
  spec.description   = %q{A Ruby workflow engine}
  spec.homepage      = "https://github.com/bumbleworks/swarm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"
  spec.add_dependency "parslet"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.7"
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency "pry"
end
