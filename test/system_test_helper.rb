# frozen_string_literal: true

require File.expand_path '../test_helper', __FILE__
require File.expand_path '../../../../test/application_system_test_case', __FILE__
require File.expand_path '../../../additionals/test/global_system_test_helper', __FILE__

module AdditionalTags
  class SystemTestCase < ApplicationSystemTestCase
    extend PluginFixturesLoader
    extend Additionals::GlobalSystemTestHelper
    include TestPermissions

    fixtures(*fixtures_list)
    use_plugin_system_test_driver

    def setup
      super
      prepare_tests
    end

    # Runs the block with plugin settings changed and restores them afterwards.
    # Not additionals' with_plugin_settings: that comes with GlobalTestHelper,
    # which makes Bullet raise on a whole rendered page.
    def with_tags_settings(settings)
      saved = Setting.plugin_additional_tags.dup
      Setting.plugin_additional_tags = saved.merge settings
      yield
    ensure
      Setting.plugin_additional_tags = saved
    end
  end
end
