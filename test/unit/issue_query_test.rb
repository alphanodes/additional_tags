# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueQueryTest < AdditionalTags::TestCase
  def setup
    prepare_tests
    User.current = users :users_002
    @project = projects :projects_001
  end

  def test_available_columns_add_tags_and_keep_core_columns
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      names = IssueQuery.new(project: @project, name: '_').available_columns.map(&:name)

      assert_includes names, :tags
      assert_includes names, :subject
    end
  end

  def test_available_columns_without_active_issue_tags_keep_core_columns
    with_plugin_settings 'additional_tags', active_issue_tags: 0 do
      names = IssueQuery.new(project: @project, name: '_').available_columns.map(&:name)

      assert_not_includes names, :tags
      assert_includes names, :subject
    end
  end

  def test_available_columns_without_permission_keep_core_columns
    Role.where(id: [1, 2, 3]).find_each { |role| role.remove_permission! :view_issue_tags }

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      names = IssueQuery.new(project: @project, name: '_').available_columns.map(&:name)

      assert_not_includes names, :tags
      assert_includes names, :subject
    end
  end

  # Second call runs into the memoized branch, which still has to hand out the
  # very same columns instead of appending the tags column once more.
  def test_available_columns_are_memoized
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      query = IssueQuery.new project: @project, name: '_'
      first = query.available_columns.map(&:name)
      second = query.available_columns.map(&:name)

      assert_equal first, second
      assert_equal 1, second.count(:tags)
    end
  end

  def test_initialize_available_filters_adds_tags_and_keeps_core_filters
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      filters = IssueQuery.new(project: @project, name: '_').available_filters

      assert filters.key?('tags')
      assert filters.key?('status_id')
    end
  end

  def test_initialize_available_filters_without_active_issue_tags_keeps_core_filters
    with_plugin_settings 'additional_tags', active_issue_tags: 0 do
      filters = IssueQuery.new(project: @project, name: '_').available_filters

      assert_not filters.key?('tags')
      assert filters.key?('status_id')
    end
  end

  def test_issues_preload_visible_tags_with_tags_column
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      query = IssueQuery.new project: @project, name: '_'
      query.column_names = %i[subject tags]
      issues = query.issues

      assert issues.any?
      assert(issues.all? { |issue| issue.instance_variable_defined? :@visible_tags },
             'tags must be preloaded, otherwise the column triggers a query per row')
    end
  end

  def test_issues_return_core_result_without_tags_column
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      query = IssueQuery.new project: @project, name: '_'
      query.column_names = %i[subject status]
      issues = query.issues

      issue_ids = issues.map(&:id)

      assert issues.any?
      assert_equal query.issue_ids.sort, issue_ids.sort
      assert_not(issues.any? { |issue| issue.instance_variable_defined? :@visible_tags })
    end
  end
end
