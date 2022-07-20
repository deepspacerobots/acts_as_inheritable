# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'acts_as_inheritable/version'

Gem::Specification.new do |spec|
  spec.name          = "acts_as_inheritable"
  spec.version       = ActsAsInheritable::VERSION
  spec.authors       = ["Deep Space Robots"]
  spec.email         = ["development@greetingcc.com"]
  spec.summary       = %q{Inheritable behavior for models with parent.}
  spec.description   = %q{This gem will let you inherit any attribute or relation from parent to child or from child to parent.}
  spec.homepage      = "https://github.com/deepspacerobots/acts_as_inheritable"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3.18"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "factory_bot", '~> 6.2', '>= 6.2.1'
  spec.add_development_dependency "faker", "~> 2.21", ">= 2.21.0"
  spec.add_development_dependency "rspec", "~> 3.11", ">= 3.11.0"
  spec.add_development_dependency "rspec-nc", "~> 0.3", ">= 0.3.0"
  spec.add_development_dependency "sqlite3", "~> 1.3"
  spec.add_development_dependency "nyan-cat-formatter", "~> 0.11"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4", ">= 0.4.3"

  spec.add_runtime_dependency 'activesupport', '~> 6.0.5.1'
  spec.add_runtime_dependency 'activerecord', '~> 6.0.5.1'
end
