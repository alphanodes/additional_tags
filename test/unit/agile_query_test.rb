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
end
