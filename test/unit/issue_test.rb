# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueTest < AdditionalTags::TestCase
  def setup
    # run as the admin
    User.current = users :users_001

    @project_a = projects :projects_001
    @project_b = projects :projects_003
  end

  def test_patch_was_applied
    assert_respond_to Issue, :available_tags, 'Issue has available_tags getter'
    assert_respond_to Issue.new, :tags, 'Issue instance has tags getter'
    assert_respond_to Issue.new, :tags=, 'Issue instance has tags setter'
    assert_respond_to Issue.new, :tag_list=, 'Issue instance has tag_list setter'
  end

  def test_available_tags_should_return_list_of_distinct_tags
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

  def test_available_tags_should_allow_list_tags_of_specific_project_only
    with_settings display_subprojects_issues: '1' do
      assert_equal 5, Issue.available_tags(project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(project: @project_b).to_a.size

      assert_equal 4, Issue.available_tags(open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(open_issues_only: true, project: @project_b).to_a.size
    end
  end

  def test_available_tags_should_allow_list_tags_of_specific_without_subprojects
    with_settings display_subprojects_issues: '0' do
      assert_equal 4, Issue.available_tags(project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(project: @project_b).to_a.size

      assert_equal 3, Issue.available_tags(open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(open_issues_only: true, project: @project_b).to_a.size
    end
  end

  def test_available_tags_should_allow_list_tags_found_by_name
    assert_equal 3, Issue.available_tags(name_like: 'i').to_a.size
    assert_equal 1, Issue.available_tags(name_like: 'rd').to_a.size
    assert_equal 2, Issue.available_tags(name_like: 's').to_a.size
    assert_equal 2, Issue.available_tags(name_like: 'e').to_a.size
  end

  def test_available_tags_should_allow_list_tags_found_by_name_with_project
    with_settings display_subprojects_issues: '1' do
      assert_equal 3, Issue.available_tags(name_like: 'f', project: @project_a).to_a.size
      assert_equal 0, Issue.available_tags(name_like: 'b', project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'sec', open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'fir', open_issues_only: true, project: @project_a).to_a.size
    end
  end

  def test_available_tags_should_allow_list_tags_found_by_name_without_subprojects
    with_settings display_subprojects_issues: '0' do
      assert_equal 2, Issue.available_tags(name_like: 'f', project: @project_a).to_a.size
      assert_equal 0, Issue.available_tags(name_like: 'b', project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'sec', open_issues_only: true, project: @project_a).to_a.size
      assert_equal 1, Issue.available_tags(name_like: 'fir', open_issues_only: true, project: @project_a).to_a.size
    end
  end

  def test_issue_all_tags_should_return_all_tags_kind_of_issue
    tags = Issue.available_tags.map(&:name)

    assert_equal %w[First Four Second Third five], tags.sort
  end

  def test_update_issue_with_unused_tags_should_remove_tag
    issue = issues :issues_005

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      assert_difference 'AdditionalTag.count', -1 do
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
      assert_difference 'AdditionalTag.count', -1 do
        issue.destroy!
      end
    end
  end

  def test_available_tags_with_project_should_respect_subprojects
    # tag exists only in subproject
    Issue.generate! project: @project_b, tag_list: 'im not exist in parent project'

    new_tag = AdditionalTag.find_by name: 'im not exist in parent project'

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

    new_tag = AdditionalTag.find_by name: 'im not exist in parent project'

    assert_not_nil new_tag

    with_settings display_subprojects_issues: '0' do
      # parent project should list all available tags without subprojects
      assert_not_includes Issue.available_tags(project: @project_a).to_a, new_tag
      # subproject
      assert_includes Issue.available_tags(project: @project_b).to_a, new_tag
    end
  end

  def test_load_visible_tags_returns_early_for_blank_input
    assert_nil Issue.load_visible_tags([])
    assert_nil Issue.load_visible_tags(nil)
  end

  def test_load_visible_tags_assigns_tags_for_visible_projects
    issue = issues :issues_001 # tagged in project_id 1 (visible to admin)
    Issue.load_visible_tags [issue]

    assert issue.instance_variable_defined?(:@visible_tags)
    assert_includes issue.instance_variable_get(:@visible_tags).map(&:name), 'First'
  end

  def test_load_visible_tags_assigns_empty_for_invisible_projects
    # Drop to anonymous user; their visible projects exclude private project 2.
    User.current = User.anonymous
    issue_in_private_project = issues :issues_004 # project_id 2 (private)
    Issue.load_visible_tags [issue_in_private_project]

    assert_equal [], issue_in_private_project.instance_variable_get(:@visible_tags)
  end

  def test_load_visible_tags_preloads_tags_association_to_avoid_n_plus_one
    # After the batch preload, the :tags association must be marked loaded on
    # every visible issue - otherwise the per-issue read in the loop below
    # would re-introduce an N+1 query.
    issues_with_tags = Issue.where(id: [1, 3, 6]).to_a # all in projects visible to admin

    Issue.load_visible_tags issues_with_tags

    issues_with_tags.each do |issue|
      assert issue.tags.loaded?, "tags association should be preloaded for issue ##{issue.id}"
    end
  end

  def test_copy_from_preserves_source_tag_list
    source = issues :issues_001 # fixture has tag "First"

    copy = Issue.new
    copy.copy_from source

    assert_equal ['First'], copy.tag_list.to_a
  end

  def test_copy_from_sets_bulk_copy_source_tag_list_accessor
    source = issues :issues_001

    copy = Issue.new
    copy.copy_from source

    # The accessor must mirror the source tags exactly so the bulk-edit hook
    # can diff against them after safe_attributes= overwrites @tag_list.
    assert_equal ['First'], copy.bulk_copy_source_tag_list
  end

  def test_copy_from_source_without_tags_leaves_lists_empty
    source = issues :issues_002 # fixture has no taggings

    copy = Issue.new
    copy.copy_from source

    assert_empty copy.tag_list.to_a
    # Important: bulk_copy_source_tag_list must be set (and empty), not nil.
    # The hook treats nil as "not a copy" and falls back to tags.to_a; an empty
    # array correctly signals "this was a copy from an untagged source".
    assert_equal [], copy.bulk_copy_source_tag_list
  end

  def test_copy_from_does_not_create_phantom_taggings_on_unsaved_record
    # Regression guard for the old `self.tags = source.tags` pattern, which
    # populated the taggings association in memory with taggable_id=nil rows.
    # With the tag_list-based copy_from, the new (unsaved) record must not
    # carry any in-memory tagging instances - they would otherwise either
    # trigger validation errors (taggable optional: false) on save, or end up
    # persisted with the wrong taggable wiring.
    source = issues :issues_001
    copy = Issue.new
    copy.copy_from source

    assert copy.new_record?
    assert_empty copy.taggings.to_a, 'unsaved copy must not have in-memory taggings'
  end

  def test_copy_from_does_not_modify_source_tagging_count
    source = issues :issues_001
    first_tag = additional_tags :tag_one
    count_before = first_tag.taggings_count

    Issue.new.copy_from source

    assert_equal count_before, first_tag.reload.taggings_count
  end
end
