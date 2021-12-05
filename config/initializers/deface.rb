# frozen_string_literal: true

plugin_dir = AdditionalsLoader.plugin_dir plugin_id: 'additional_tags'
Rails.autoloaders.main.push_dir "#{plugin_dir}/lib"
