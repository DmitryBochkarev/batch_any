# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'batch_any/version'

Gem::Specification.new do |spec|
  spec.name          = "batch_any"
  spec.version       = BatchAny::VERSION
  spec.authors       = ["Dmitry Bochkarev"]
  spec.email         = ["dimabochkarev@gmail.com"]

  spec.summary       = %q{Practical application of ruby fibers. Help you to batching requests.}
  spec.description   = %q{Allows you to use the batching service both for grouping requests into one and a single \
    access to api. It makes it easy to integrate the batching service into the current logic without huge refactoring.}
  spec.homepage      = "https://github.com/DmitryBochkarev/batch_any"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
