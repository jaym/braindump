# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'braindump/version'

Gem::Specification.new do |spec|
  spec.name          = "braindump"
  spec.version       = Braindump::VERSION
  spec.authors       = ["Jay Mundrawala"]
  spec.email         = ["jdmundrawala@gmail.com"]

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = %w( braindump )
  spec.require_paths = ["lib"]

  spec.add_dependency "test-kitchen", "~> 1.4.0"
  spec.add_dependency "facets", "~> 3.0.0"
  spec.add_dependency "pidfile", "~> 0.3.0"
  spec.add_dependency "rugged", "~> 0.22.2"
  spec.add_dependency "mixlib-versioning", "~> 1.1.0"
  spec.add_dependency "rest-client", "~> 1.8.0"
  spec.add_dependency "nokogiri", "~> 1.6.6"
  spec.add_dependency "thor", "~> 0.19.1"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
