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

  spec.summary       = "CLI for automating the deployment of application cookbooks"
  spec.description   = <<-EOF
                         This CLI automatically rebuilds and deploys your cookbook
                         when changes are detected. Application deployment is
                         supported for OpsWorks stacks and ubuntu SSH hosts.
                       EOF
  spec.homepage      = "https://github.com/chris-allen/dream-ops"
  spec.license       = "MIT"
  spec.metadata      = {
    "source_code_uri" => "https://github.com/chris-allen/dream-ops",
    "changelog_uri"   => "https://github.com/chris-allen/dream-ops/blob/master/CHANGELOG.md"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "rubyzip",   "~> 1.2"
  spec.add_dependency "aws-sdk",   "~> 2"
  spec.add_dependency "berkshelf", "~> 7.0"
  spec.add_dependency "thor",      "~> 0.20"
  spec.add_dependency "chef",      "~> 13.6"
end
