# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

# Every setting the settings form of the block sends is declared by it
class AdditionalTagsDashboardBlockSettingsFormTest < AdditionalTags::ControllerTest
  tests WelcomeController

  def setup
    prepare_tests
    Setting.default_language = 'en'
  end

  def test_settings_form_of_issue_tags_sends_declared_settings_only
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_dashboard_block_settings_declared %w[issue_tags]
    end
  end
end
