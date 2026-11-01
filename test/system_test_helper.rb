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

    # The tag field interactions are kept here, so the tests do not depend on
    # the markup of the select library behind the field.

    # Types into the tag field inside +container+ and picks the suggestion
    # +text+ the server returns for it
    def choose_tag_suggestion(container, search, text)
      tag_field_search(container).send_keys search
      find('.select2-results__option', text:, exact_text: true).click
    end

    def tag_field_search(container)
      within(container) { find('.select2-selection').click }
      find '.select2-container--open .select2-search__field'
    end
  end
end
