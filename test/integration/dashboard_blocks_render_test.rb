# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

# The block of additional_tags renders, with the page and loaded after it
class AdditionalTagsDashboardBlocksRenderTest < AdditionalTags::IntegrationTest
  def test_welcome_blocks_render
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_dashboard_blocks_render %w[issue_tags]
    end
  end

  def test_project_blocks_render
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_dashboard_blocks_render %w[issue_tags], project: projects(:projects_001)
    end
  end
end
