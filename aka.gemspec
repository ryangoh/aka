# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aka/version'

Gem::Specification.new do |spec|
  spec.name          = "aka"
  spec.version       = Aka::VERSION
  spec.authors       = ["Ryan Goh"]
  spec.email         = ["gohengkeat89@gmail.com"]

  spec.summary       = %q{The Missing Alias Manager}
  spec.description   = %q{aka generate/edit/destroy/find permanent aliases with a single command. }
  spec.homepage      = "https://github.com/ryangoh/aka"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  #spec.bindir        = "exe"
  #spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.executables   = ["aka"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.2.2"
  spec.add_dependency "net/scp" , '~> 1.2.1'
  spec.add_dependency "open-uri" , '~> '
  spec.add_dependency "colorize" , '~> 0.7.5'
  spec.add_dependency "safe_yaml/load" , '~> 1.0.4'
  spec.add_dependency "thor" , '~> 0.19.1'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.7"
end
