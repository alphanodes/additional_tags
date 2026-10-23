# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class ContextMenusIssuesControllerTest < AdditionalTags::ControllerTest
  tests ContextMenus::IssuesController

  def setup
    prepare_tests
    @request.session[:user_id] = 2
  end

  # Several issues get tags added or removed, a single issue gets them added or edited
  def test_issues_tags_entries
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      { [1, 2] => %w[append remove], [1] => %w[append edit] }.each do |ids, modes|
        get :index, params: { ids: }

        links = css_select('a[href*="issue_tags/edit"]').map { |a| a['href'][/mode=(\w+)/, 1] || 'edit' }

        assert_equal modes, links, "ids #{ids}"
      end
    end
  end
end
