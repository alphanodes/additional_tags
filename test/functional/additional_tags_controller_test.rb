# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class AdditionalTagsControllerTest < AdditionalTags::ControllerTest
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :additional_tags, :additional_taggings

  def setup
    prepare_tests
    # run as the admin
    @request.session[:user_id] = 1

    @project_a = Project.generate!
    @project_b = Project.generate!

    add_issue @project_a, %w[a1 a2], false
    add_issue @project_a, %w[a4 a5], true
    add_issue @project_b, %w[b6 b7], true
    add_issue @project_b, %w[b8 b9], false
  end

  def test_should_get_edit
    tag = ActsAsTaggableOn::Tag.find_by name: 'a1'
    get :edit,
        params: { id: tag.id }
    assert_response :success
    assert_select "input#tag_name[value='#{tag.name}']", 1
  end

  def test_should_put_update
    tag1 = ActsAsTaggableOn::Tag.find_by name: 'a1'
    new_name = 'updated main'
    put :update,
        params: { id: tag1.id, tag: { name: new_name } }

    assert_redirected_to controller: 'settings', action: 'plugin', id: 'additional_tags', tab: 'manage_tags'
    tag1.reload
    assert_equal new_name, tag1.name
  end

  def test_should_post_destroy
    tag1 = ActsAsTaggableOn::Tag.find_by name: 'a1'
    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      post :destroy,
           params: { ids: tag1.id }
      assert_response 302
    end
  end

  def test_should_post_merge
    tag1 = ActsAsTaggableOn::Tag.find_by name: 'a1'
    tag2 = ActsAsTaggableOn::Tag.find_by name: 'b8'
    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      post :merge,
           params: { ids: [tag1.id, tag2.id], tag: { name: 'a1' } }
      assert_redirected_to controller: 'settings', action: 'plugin', id: 'additional_tags', tab: 'manage_tags'
    end
    assert_equal 0, Issue.tagged_with('b8').count
    assert_equal 2, Issue.tagged_with('a1').count
  end

  def test_should_destroy_tags_without_relations
    tag1 = ActsAsTaggableOn::Tag.find_by name: 'a1'
    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      post :destroy,
           params: { ids: tag1.id }
      assert_response 302
    end
  end

  private

  def add_issue(project, tags, closed)
    issue = Issue.generate! project_id: project.id
    issue.tag_list = tags
    issue.status = IssueStatus.where(is_closed: true).sorted.first if closed
    issue.save
  end
end
