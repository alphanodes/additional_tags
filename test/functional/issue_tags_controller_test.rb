# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueTagsControllerTest < AdditionalTags::ControllerTest
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
    @request.env['HTTP_REFERER'] = '/issue_tags'

    @request.session[:user_id] = 2
    @project_1 = projects :projects_001
    @issue_1 = issues :issues_001
    @issue_2 = issues :issues_002
    @issue_8 = issues :issues_008
    @issues = [@issue_1, @issue_2, @issue_8]
    @ids = [1, 2, 8]
    @most_used_tags = %w[Second Third First]
    @role = roles :roles_001 # Manager role
  end

  def test_should_get_edit_when_one_issue_chose
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :edit,
          params: { ids: [6] },
          xhr: true

      assert_response :success
      assert_equal 'text/javascript', response.media_type

      html_form = response.body[/<form.+form>/].delete('\\')
      assert_select_in html_form, 'select#issue_tag_list', 1 do
        assert_select 'option[selected="selected"]', 2
        assert_select 'option[selected="selected"]', text: 'Four'
        assert_select 'option[selected="selected"]', text: 'Second'
      end

      assert_select_in html_form, '.most-used-tags' do
        assert_select '.most-used-tag', 4
        @most_used_tags.each { |tag| assert_select '.most-used-tag', text: tag, count: 1 }
      end
    end
  end

  def test_should_get_edit_when_several_issues_chose
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :edit,
          params: { ids: @ids },
          xhr: true

      assert_response :success
      assert_equal 'text/javascript', response.media_type

      html_form = response.body[/<form.+form>/].delete('\\')

      assert_select_in html_form, 'select#issue_tag_list', 1 do
        assert_select 'option[selected="selected"]', 1
      end

      assert_select_in html_form, '.most-used-tags' do
        assert_select '.most-used-tag', 4
        @most_used_tags.each { |tag| assert_select '.most-used-tag', text: tag, count: 1 }
      end
    end
  end

  def test_should_get_not_found_when_no_ids
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :edit,
          params: { ids: [] },
          xhr: true

      assert_response :missing

      post :update,
           params: { ids: [], issue: { tag_list: [] } }

      assert_response :missing
    end
  end

  def test_should_change_issue_tags_empty_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: [1], issue: { tag_list: ['', '', ''] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_kind_of Array, @issue_1.tag_list
      assert_empty @issue_1.tag_list
    end
  end

  def test_should_change_issue_tags_no_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: [1], issue: { tag_list: [] } }

      assert_response :redirect

      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_kind_of Array, @issue_1.tag_list
      assert_empty @issue_1.tag_list
    end
  end

  def test_should_change_issue_tags_one_tag
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: [1], issue: { tag_list: %w[first] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_equal %w[First], @issue_1.tag_list
    end
  end

  def test_should_change_issue_tags_several_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: [1], issue: { tag_list: %w[first second third] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_equal %w[First Second Third], @issue_1.tag_list.sort
    end
  end

  def test_should_bulk_change_issue_tags_no_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: @ids, issue: { tag_list: [] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      @issues.each { |issue| assert_empty issue.tag_list }
    end
  end

  def test_should_bulk_change_issue_tags_one_tag
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: @ids, issue: { tag_list: %w[first] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      @issues.each { |issue| assert_equal %w[First], issue.tag_list }
    end
  end

  def test_should_bulk_change_issue_tags_several_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: @ids, issue: { tag_list: %w[first second third] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      @issues.each { |issue| assert_equal %w[First Second Third], issue.tag_list.sort }
    end
  end

  def test_edit_tags_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      tag = 'Second'
      user = users :users_002

      assert_not_equal @issue_1.tag_list, [tag]
      assert_includes Issue.available_tags(user: user).map(&:name), tag
      post :update,
           params: { ids: [1], issue: { tag_list: [tag] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_equal Issue.find(1).tag_list, [tag]

      @role.remove_permission! :edit_issue_tags
      tag2 = 'Third'

      assert_includes Issue.available_tags(user: user).map(&:name), tag2
      post :update,
           params: { ids: [1], issue: { tag_list: [tag2] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error]
      assert_equal Issue.find(1).tag_list, [tag]
    end
  end

  def test_bulk_edit_tags_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      tag = 'First'

      assert_includes Issue.all_tags.map(&:name), tag
      post :update,
           params: { ids: [1, 2], issue: { tag_list: [tag] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_equal Issue.find(1).tag_list, [tag]
      assert_equal Issue.find(2).tag_list, [tag]
    end
  end

  def test_bulk_edit_tags_without_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 7
      tag = 'Second'

      assert_includes Issue.all_tags.map(&:name), tag
      post :update,
           params: { ids: [1, 2], issue: { tag_list: [tag] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error]
      assert_not Issue.find(1).tag_list.include?(tag)
      assert_not Issue.find(2).tag_list.include?(tag)
    end
  end

  def test_create_tags_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      new_tag = 'enable_create_tags_permission'

      assert_not_equal Issue.find(1).tag_list, [new_tag]
      assert_not Issue.all_tags.map(&:name).include?(new_tag)
      post :update,
           params: { ids: [1], issue: { tag_list: [new_tag] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_equal Issue.find(1).tag_list, [new_tag]

      @role.remove_permission! :create_issue_tags
      new_tag2 = 'disable_create_tags_permission'

      assert_not Issue.all_tags.map(&:name).include?(new_tag2)
      post :update,
           params: { ids: [1], issue: { tag_list: [new_tag2] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error]
      assert_equal Issue.find(1).tag_list, [new_tag]
    end
  end

  def test_should_append_tag_for_multiple_issues
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: [1], issue: { tag_list: %w[First] } }

      post :update,
           params: { ids: [2], issue: { tag_list: %w[Second] } }

      assert_difference 'Journal.count', 2 do
        post :update,
             params: { ids: [1, 2], issue: { tag_list: %w[New] }, append: 'true' }

        assert_response :redirect
        assert_redirected_to action: 'update'
        assert_sorted_equal %w[First New], Issue.find(1).tag_list
        assert_sorted_equal %w[Second New], Issue.find(2).tag_list
      end
    end
  end

  def test_should_get_empty_option_when_add_for_multiple_issue
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update,
           params: { ids: [1], issue: { tag_list: ['First'] } }

      post :update,
           params: { ids: [2], issue: { tag_list: ['Second'] } }

      get :edit,
          params: { ids: [1, 2], append: 'true' },
          xhr: true

      assert_response :success
      assert_equal 'text/javascript', response.media_type

      html_form = response.body[/<form.+form>/].delete('\\')
      assert_select_in html_form, 'select#issue_tag_list', 1 do
        assert_select 'option[selected="selected"]', 0
      end
    end
  end
end
