# frozen_string_literal: true

lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'additional_tags/plugin_version'

Gem::Specification.new do |spec|
  spec.name          = 'additional_tags'
  spec.version       = AdditionalTags::PluginVersion::VERSION
  spec.authors       = ['AlphaNodes']
  spec.email         = ['alex@alphanodes.com']
  spec.metadata      = { 'rubygems_mfa_required' => 'true' }

  spec.summary       = 'Redmine plugin for adding tag functionality'
  spec.description   = 'Redmine plugin for adding tag functionality'
  spec.homepage      = 'https://github.com/alphanodes/additional_tags'
  spec.license       = 'GPL-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match %r{^((test|spec|features)/|Gemfile)}
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename f }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7'

  spec.add_runtime_dependency 'acts-as-taggable-on', '~> 9.0'
  spec.add_runtime_dependency 'redmine_plugin_kit'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
