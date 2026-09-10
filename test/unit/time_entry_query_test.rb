# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TimeEntryQueryTest < AdditionalTags::TestCase
  def setup
    prepare_tests
    User.current = users :users_002
    @project = projects :projects_001
  end

  def test_available_columns_add_issue_tags_and_keep_core_columns
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      names = TimeEntryQuery.new(project: @project, name: '_').available_columns.map(&:name)

      assert_includes names, :issue_tags
      assert_includes names, :spent_on
    end
  end

  def test_available_columns_without_active_issue_tags_keep_core_columns
    with_plugin_settings 'additional_tags', active_issue_tags: 0 do
      names = TimeEntryQuery.new(project: @project, name: '_').available_columns.map(&:name)

      assert_not_includes names, :issue_tags
      assert_includes names, :spent_on
    end
  end

  # Second call runs into the memoized branch, which still has to hand out the
  # very same columns instead of appending the tags column once more.
  def test_available_columns_are_memoized
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      query = TimeEntryQuery.new project: @project, name: '_'
      first = query.available_columns.map(&:name)
      second = query.available_columns.map(&:name)

      assert_equal first, second
      assert_equal 1, second.count(:issue_tags)
    end
  end

  def test_initialize_available_filters_adds_issue_tags_and_keeps_core_filters
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      filters = TimeEntryQuery.new(project: @project, name: '_').available_filters

      assert filters.key?('issue.tags')
      assert filters.key?('spent_on')
    end
  end

  def test_initialize_available_filters_without_active_issue_tags_keeps_core_filters
    with_plugin_settings 'additional_tags', active_issue_tags: 0 do
      filters = TimeEntryQuery.new(project: @project, name: '_').available_filters

      assert_not filters.key?('issue.tags')
      assert filters.key?('spent_on')
    end
  end
end
