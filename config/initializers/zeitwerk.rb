# frozen_string_literal: true

if Rails.version > '6.0'
  plugin_dir = RedminePluginKit::Loader.plugin_dir plugin_id: 'additional_tags'
  Rails.autoloaders.main.push_dir "#{plugin_dir}/lib"
end
