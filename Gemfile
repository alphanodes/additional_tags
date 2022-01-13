# frozen_string_literal: true

# Specify your gem's dependencies in additional_tags.gemspec
gemspec

# if you want to use it for linters, do:
# - create .enable_test file in additionals directory
# - remove rubocop entries from REDMINE/Gemfile
# - remove REDMINE/.rubocop* files
if File.file? File.expand_path './.enable_linters', __dir__
  group :development, :test do
    gem 'brakeman', require: false
    gem 'pandoc-ruby', require: false
    gem 'rubocop', require: false
    gem 'rubocop-performance', require: false
    gem 'rubocop-rails', require: false
    gem 'slim_lint', require: false
  end
end

# if you want to use it for tests, do:
# - create .enable_test file in additionals directory
# - remove rubocop entries from REDMINE/Gemfile
# - remove REDMINE/.rubocop* files
if File.file? File.expand_path './.enable_test', __dir__
  group :development, :test do
    gem 'active_record_doctor', require: false
    gem 'bullet'
  end
end
