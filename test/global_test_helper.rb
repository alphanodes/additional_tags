# frozen_string_literal: true

module AdditionalTags
  module GlobalTestHelper
    def with_tags_settings(settings, &_block)
      saved_settings = Setting.plugin_additional_tags.dup
      new_settings = Setting.plugin_additional_tags.dup
      settings.each do |key, value|
        new_settings[key] = value
      end
      Setting.plugin_additional_tags = new_settings
      yield
    ensure
      Setting.plugin_additional_tags = saved_settings
    end
  end
end
