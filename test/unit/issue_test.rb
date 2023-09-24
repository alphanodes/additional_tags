# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueTest < AdditionalTags::TestCase
  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries,
           :journals, :journal_details,
           :additional_tags, :additional_taggings

  def setup
    # run as the admin
    User.stubs(:current).returns(users(:users_001))

    @project_a = projects :projects_001
    @project_b = projects :projects_003
  end

  test 'patch was applied' do
    assert_respond_to Issue, :available_tags, 'Issue has available_tags getter'
    assert_respond_to Issue.new, :tags, 'Issue instance has tags getter'
    assert_respond_to Issue.new, :tags=, 'Issue instance has tags setter'
    assert_respond_to Issue.new, :tag_list=, 'Issue instance has tag_list setter'
  end

  test 'available tags should return list of distinct tags' do
    assert_equal 5, Issue.available_tags.to_a.size
  end

  def test_open_issue_tags
    assert_operator Issue.available_tags(open_issues_only: true).to_a.size, :<, Issue.available_tags.to_a.size
  end

  def test_group_by_status_with_tags
    assert_equal 6, Issue.group_by_status_with_tags.size
  end

  def test_group_by_status_with_tags_for_project
    with_settings display_subprojects_issues: '1' do
      assert_equal 6, Issue.group_by_status_with_tags(@project_a).size
    end
  end

  def test_group_by_status_with_tags_without_subprojects
    with_settings display_subprojects_issues: '0' do
      assert_equal 5, Issue.group_by_status_with_tags(@project_a).size
    end
  end

  test 'available tags should allow list tags of specific project only' do
    with_settings display_subprojects_issues: '1' do
      assert_equal 5, Issue.available_tags(project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(project: @project_b).to_a.size

      assert_equal 4, Issue.available_tags(open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(open_issues_only: true, project: @project_b).to_a.size
    end
  end

  test 'available tags should allow list tags of specific without subprojects' do
    with_settings display_subprojects_issues: '0' do
      assert_equal 4, Issue.available_tags(project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(project: @project_b).to_a.size

      assert_equal 3, Issue.available_tags(open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(open_issues_only: true, project: @project_b).to_a.size
    end
  end

  test 'available tags should allow list tags found by name' do
    assert_equal 3, Issue.available_tags(name_like: 'i').to_a.size
    assert_equal 1, Issue.available_tags(name_like: 'rd').to_a.size
    assert_equal 2, Issue.available_tags(name_like: 's').to_a.size
    assert_equal 2, Issue.available_tags(name_like: 'e').to_a.size
  end

  test 'available tags should allow list tags found by name with project' do
    with_settings display_subprojects_issues: '1' do
      assert_equal 3, Issue.available_tags(name_like: 'f', project: @project_a).to_a.size
      assert_equal 0, Issue.available_tags(name_like: 'b', project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'sec', open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'fir', open_issues_only: true, project: @project_a).to_a.size
    end
  end

  test 'available tags should allow list tags found by name without subprojects' do
    with_settings display_subprojects_issues: '0' do
      assert_equal 2, Issue.available_tags(name_like: 'f', project: @project_a).to_a.size
      assert_equal 0, Issue.available_tags(name_like: 'b', project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'sec', open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'fir', open_issues_only: true, project: @project_a).to_a.size
    end
  end

  test 'Issue.all_tags should return all tags kind of Issue' do
    tags = Issue.available_tags.map(&:name)

    assert_equal %w[First Four Second Third five], tags.sort
  end

  def test_update_issue_with_unused_tags_should_remove_tag
    issue = issues :issues_005

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
        issue.tag_list = []

        assert_save issue
      end
    end
  end

  def test_destroy_issue_with_unused_tags_should_remove_tag
    issue = issues :issues_002
    issue.tag_list << 'unused_new_tag'

    assert_save issue

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
        issue.destroy!
      end
    end
  end

  def test_available_tags_with_project_should_respect_subprojects
    # tag exists only in subproject
    Issue.generate! project: @project_b, tag_list: 'im not exist in parent project'

    new_tag = ActsAsTaggableOn::Tag.find_by name: 'im not exist in parent project'

    assert_not_nil new_tag

    with_settings display_subprojects_issues: '1' do
      # parent project should list all available tags including subprojects
      assert_includes Issue.available_tags(project: @project_a).to_a, new_tag
      # subproject
      assert_includes Issue.available_tags(project: @project_b).to_a, new_tag
    end
  end

  def test_available_tags_with_project_should_ignore_subprojects_if_disabled
    # tag exists only in subproject
    Issue.generate! project: @project_b, tag_list: 'im not exist in parent project'

    new_tag = ActsAsTaggableOn::Tag.find_by name: 'im not exist in parent project'

    assert_not_nil new_tag

    with_settings display_subprojects_issues: '0' do
      # parent project should list all available tags without subprojects
      assert_not_includes Issue.available_tags(project: @project_a).to_a, new_tag
      # subproject
      assert_includes Issue.available_tags(project: @project_b).to_a, new_tag
    end
  end
end
