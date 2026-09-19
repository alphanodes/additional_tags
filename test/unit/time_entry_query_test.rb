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

  # Time entries 1 and 2 belong to issue 1 (tag First), entry 3 to issue 3
  # (tag Second). Entry 4 has no issue, entry 5 is outside the project.
  def test_issue_tags_filter
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_equal [1, 2], time_entry_ids_for('=', ['First'])
      assert_equal [1, 2, 3], time_entry_ids_for('=', %w[First Second])
      # Entry 4 has no issue and therefore no issue tag: it belongs to every negation
      assert_equal [3, 4], time_entry_ids_for('!', ['First'])
      assert_equal [1, 2, 3], time_entry_ids_for('*')
      assert_equal [4], time_entry_ids_for('!*')
      assert_empty time_entry_ids_for('=', ['deleted tag'])
      # nothing carries a deleted tag, so the negation keeps every entry
      assert_equal [1, 2, 3, 4], time_entry_ids_for('!', ['deleted tag'])
    end
  end

  # Not used by a query of this plugin, but by the relation filters of
  # servicedesk, db and passwords: the tagged object is joined to the queried one.
  def test_build_subquery_for_tags_field
    query = TimeEntryQuery.new project: @project, name: '_'

    assert_equal [1, 2], time_entry_ids_for_subquery(query, '=', ['First'])
    assert_equal [3, 4, 5], time_entry_ids_for_subquery(query, '!', ['First'])
    assert_equal [1, 2, 3], time_entry_ids_for_subquery(query, '*')
    assert_equal [4, 5], time_entry_ids_for_subquery(query, '!*')
    assert_empty time_entry_ids_for_subquery(query, '=', ['deleted tag'])
    # nothing carries a deleted tag, so the negation keeps every entry
    assert_equal [1, 2, 3, 4, 5], time_entry_ids_for_subquery(query, '!', ['deleted tag'])
  end

  private

  def time_entry_ids_for(operator, values = [''])
    User.current = users :users_001
    query = TimeEntryQuery.new project: @project, name: '_'
    query.filters = {}
    query.add_filter 'issue.tags', operator, values

    query.results_scope.ids.sort
  end

  def time_entry_ids_for_subquery(query, operator, values = [''])
    sql = query.build_subquery_for_tags_field klass: Issue,
                                              operator:,
                                              values:,
                                              joined_table: Issue.table_name,
                                              joined_field: 'id',
                                              source_field: 'issue_id',
                                              target_field: 'id'

    TimeEntry.where(sql).ids.sort
  end
end
