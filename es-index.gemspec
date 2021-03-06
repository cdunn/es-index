# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'es/index/version'

Gem::Specification.new do |spec|
  spec.name          = "es-index"
  spec.version       = ES::Index::VERSION
  spec.authors       = ["Cary Dunn"]
  spec.email         = ["cary.dunn@gmail.com"]
  spec.description   = "Elasticsearch + toy-dynamo"
  spec.summary       = "Elasticsearch + toy-dynamo"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "hashie", ">= 2.0"
end
