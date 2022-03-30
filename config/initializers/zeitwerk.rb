# frozen_string_literal: true

plugin_dir = RedminePluginKit::Loader.plugin_dir plugin_id: 'additional_tags'
Rails.autoloaders.main.push_dir "#{plugin_dir}/lib"
