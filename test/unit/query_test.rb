# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class QueryTest < AdditionalTags::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :issue_statuses, :enumerations,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :roles,
           :additional_tags, :additional_taggings

  def setup
    Issue.destroy_all
    Issue.generate! project_id: 1, tag_list: ['First Issue'] # eCookBook
    Issue.generate! project_id: 1, tag_list: ['Second Issue'] # eCookBook
    Issue.generate! project_id: 3, tag_list: ['Third Issue'] # eCookBook Subproject 1
    User.current = users :users_002
    prepare_tests
    # eCookBook Subproject 1 => Reporter
    User.add_to_project users(:users_002), projects(:projects_003), roles(:roles_003)
    @project = projects :projects_001
  end

  def test_query_tag_filter_including_subprojects
    with_settings display_subprojects_issues: 1 do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        query = IssueQuery.new project: @project, name: '_'
        query.add_filter 'tags', '*', ['']
        # All 3 visible to the user
        assert_equal 3, query.issues.count
      end
    end
  end

  def test_query_tag_filter_including_subprojects_without_permission
    # Remove permission for Reporter role
    Role.find(3).remove_permission!(:view_issue_tags)

    with_settings display_subprojects_issues: 1 do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        query = IssueQuery.new project: @project, name: '_'
        query.add_filter 'tags', '*', ['']
        # Only issues from parent project, no subproject
        assert_equal 2, query.issues.count
        assert(query.issues.all? { |i| i.project.id == @project.id })
      end
    end
  end
end
