# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__

class QueriesHelperTest < AdditionalTags::HelperTest
  include QueriesHelper
  include AdditionalTagsHelper

  def setup
    super
    prepare_tests
    User.current = users :users_002
  end

  def test_column_content_renders_tag_links_for_issue
    issue = issues :issues_001

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      result = column_content QueryTagsColumn.new, issue

      assert_include additional_tags(:tag_one).name, result
      assert_include '/issues?', result
    end
  end

  def test_column_content_renders_preloaded_visible_tags
    issue = issues :issues_001
    Issue.load_visible_tags [issue]

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      result = column_content QueryTagsColumn.new, issue

      assert_include additional_tags(:tag_one).name, result
    end
  end

  # The tags branch must only trigger for the tag columns; everything else has
  # to reach Redmine core through super.
  def test_column_content_of_core_column_is_rendered_by_core
    issue = issues :issues_001

    result = column_content QueryColumn.new(:subject), issue

    assert_equal link_to(issue.subject, issue_path(issue)), result
  end

  def test_column_content_renders_tag_links_for_time_entry
    entry = time_entries :time_entries_001

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      result = column_content QueryColumn.new(:issue_tags), entry

      assert_include additional_tags(:tag_one).name, result
    end
  end
end
