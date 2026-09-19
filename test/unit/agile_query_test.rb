# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

# redmine_agile is an optional dependency, so this only runs where it is
# installed. AgileQuery gets the same tags filter as IssueQuery, and the patch
# is prepended, so core's own filters have to survive the chain.
class AgileQueryTest < AdditionalTags::TestCase
  def setup
    skip 'redmine_agile not installed' unless defined? AgileQuery

    prepare_tests
    User.current = users :users_002
    @project = projects :projects_001
  end

  def test_available_filters_add_tags_and_keep_core_filters
    keys = AgileQuery.new(project: @project, name: '_').available_filters.keys

    assert_includes keys, 'tags'
    assert_includes keys, 'tracker_id'
    assert_includes keys, 'subject'
  end

  def test_available_filters_without_permission_keep_core_filters
    Role.where(id: [1, 2, 3]).find_each { |role| role.remove_permission! :view_issue_tags }

    keys = AgileQuery.new(project: @project, name: '_').available_filters.keys

    assert_not_includes keys, 'tags'
    assert_includes keys, 'tracker_id'
  end

  def test_available_columns_carry_the_tags_column
    names = AgileQuery.new(project: @project, name: '_').available_columns.map(&:name)

    assert_includes names, :tags
  end

  # Issues 1 and 8 are tagged First, issue 3 Second, issue 2 carries no tag.
  def test_tags_filter
    User.current = users :users_001

    assert_equal [1, 8], issue_ids_for('=', ['First'])
    assert_not_includes issue_ids_for('!', ['First']), 1
    assert_includes issue_ids_for('!', ['First']), 2
    assert_includes issue_ids_for('*'), 3
    assert_not_includes issue_ids_for('*'), 2
    assert_includes issue_ids_for('!*'), 2
    assert_not_includes issue_ids_for('!*'), 3
    assert_empty issue_ids_for('=', ['deleted tag'])
  end

  # The condition alone says nothing about the query carrying it: an agile query brings a
  # scope of its own, which is why issue 8 stays out here although it carries the tag.
  def test_tags_filter_narrows_the_query_itself
    User.current = users :users_001
    query = AgileQuery.new project: @project, name: '_'
    query.filters = {}
    query.add_filter 'tags', '=', ['First']

    assert_equal [1], query.issues.ids
  end

  private

  def issue_ids_for(operator, values = [''])
    query = AgileQuery.new project: @project, name: '_'
    query.filters = {}
    query.add_filter 'tags', operator, values

    Issue.where(query.sql_for_tags_field('tags', operator, values)).ids.sort
  end
end
