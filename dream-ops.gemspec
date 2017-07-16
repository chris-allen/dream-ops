# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dream-ops/version"

Gem::Specification.new do |spec|
  spec.name          = "dream-ops"
  spec.version       = DreamOps::VERSION
  spec.authors       = ["Chris Allen"]
  spec.email         = ["chris@apaxsoftware.com"]
  spec.required_ruby_version     = ">= 2.3.1"
  spec.required_rubygems_version = ">= 2.0.0"

  spec.summary       = "This is the summary"
  spec.description   = "This is the description"
  spec.homepage      = "https://github.com/chris-allen/dream-ops"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "rubyzip",   "~> 1.2"
  spec.add_dependency "aws-sdk",   "~> 2"
  spec.add_dependency "berkshelf", "~> 6.2"
  spec.add_dependency "ridley",    "~> 5.0"
  spec.add_dependency "thor",      "~> 0.19", "< 0.19.2"
  spec.add_dependency "chef",      "~> 12.7"
end
