# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueTagsControllerTest < AdditionalTags::ControllerTest
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

  # Tags of several issues are merged, so they need sorting again - like everywhere else,
  # independent of case and accents, not by character code ("Zebra" before "äpfel")
  def test_edit_several_issues_lists_their_tags_alphabetically
    @issue_1.update! tag_list: %w[Zebra]
    @issue_2.update! tag_list: %w[äpfel Birne]

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :edit, params: { ids: [1, 2] }, xhr: true

      html_form = response.body[/<form.+form>/].delete('\\')
      options = assert_select_in html_form, 'select#issue_tag_list option'

      assert_equal %w[äpfel Birne Zebra], options.map(&:text)
    end
  end

  # The tags of all chosen issues are loaded at once, not per issue
  def test_edit_several_issues_loads_their_tags_with_a_constant_number_of_queries
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      two_issues = count_sql_queries(matching: /additional_taggings/) { get :edit, params: { ids: [1, 2] }, xhr: true }
      three_issues = count_sql_queries(matching: /additional_taggings/) { get :edit, params: { ids: @ids }, xhr: true }

      assert_equal two_issues, three_issues
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
      assert_includes Issue.available_tags(user:).map(&:name), tag
      post :update,
           params: { ids: [1], issue: { tag_list: [tag] } }

      assert_response :redirect
      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_equal Issue.find(1).tag_list, [tag]

      @role.remove_permission! :edit_issue_tags
      tag2 = 'Third'

      assert_includes Issue.available_tags(user:).map(&:name), tag2
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

  # Issue 1 is in project 1 (Manager), issue 4 in project 2 (Developer), both roles of user 2
  def test_bulk_change_across_projects_needs_permission_in_every_project
    issue_4_tags = issues(:issues_004).tag_list.to_a

    { edit_issue_tags: %w[First], create_issue_tags: %w[brand_new_tag] }.each do |permission, tags|
      roles(:roles_002).remove_permission! permission

      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        post :update, params: { ids: [1, 4], issue: { tag_list: tags } }

        assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error], permission
        assert_equal issue_4_tags, issues(:issues_004).reload.tag_list, permission
      end

      roles(:roles_002).add_permission! permission
    end
  end

  # The Developer role of project 2 must not create tags, existing ones can still be added there
  def test_bulk_change_across_projects_with_existing_tags_without_permission_to_create_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update, params: { ids: [1, 4], issue: { tag_list: %w[First] }, mode: 'append' }

      assert_equal I18n.t(:notice_tags_added), flash[:notice]
      assert_includes issues(:issues_004).reload.tag_list, 'First'
    end
  end

  def test_edit_across_projects_offers_new_tags_with_permission_in_every_project
    roles(:roles_002).add_permission! :create_issue_tags

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :edit, params: { ids: [1, 4], mode: 'append' }, xhr: true

      assert_response :success
      assert_includes response.body.delete('\\'), '"tags":true'
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
             params: { ids: [1, 2], issue: { tag_list: %w[New] }, mode: 'append' }

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
          params: { ids: [1, 2], mode: 'append' },
          xhr: true

      assert_response :success
      assert_equal 'text/javascript', response.media_type

      html_form = response.body[/<form.+form>/].delete('\\')
      assert_select_in html_form, 'select#issue_tag_list', 1 do
        assert_select 'option[selected="selected"]', 0
      end
    end
  end

  # Removing offers every tag of the chosen issues, not only the shared ones, and none is preselected
  def test_edit_for_removal_lists_tags_of_all_issues_unselected
    @issue_1.update! tag_list: %w[First Second]
    @issue_2.update! tag_list: %w[Third]

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :edit, params: { ids: [1, 2], mode: 'remove' }, xhr: true

      assert_response :success

      html_form = response.body[/<form.+form>/].delete('\\')
      options = assert_select_in html_form, 'select#issue_tag_list option'

      assert_equal %w[First Second Third], options.map(&:text)
      assert_select_in html_form, 'select#issue_tag_list option[selected]', 0
      assert_select_in html_form, '.most-used-tags', 0
      assert_select_in html_form, 'input[type=submit][value=?]', I18n.t(:button_remove)
    end
  end

  def test_should_remove_tags_from_multiple_issues
    @issue_1.update! tag_list: %w[First Second]
    @issue_2.update! tag_list: %w[Second Third]
    @issue_8.update! tag_list: %w[Third]

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      # issue 8 has none of the removed tags and gets no journal
      assert_difference 'Journal.count', 2 do
        post :update, params: { ids: @ids, issue: { tag_list: %w[First Second] }, mode: 'remove' }
      end

      assert_redirected_to action: 'update'
      assert_equal I18n.t(:notice_tags_removed), flash[:notice]
      assert_empty @issue_1.reload.tag_list
      assert_equal %w[Third], @issue_2.reload.tag_list
      assert_equal %w[Third], @issue_8.reload.tag_list
    end
  end

  # Removing creates no tag, so it does not need the permission to create tags
  def test_remove_tags_without_permission_to_create_tags
    @issue_1.update! tag_list: %w[First]
    @role.remove_permission! :create_issue_tags

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update, params: { ids: [1], issue: { tag_list: %w[First unknown_tag] }, mode: 'remove' }

      assert_equal I18n.t(:notice_tags_removed), flash[:notice]
      assert_empty @issue_1.reload.tag_list
    end
  end

  def test_remove_tags_without_permission
    @issue_1.update! tag_list: %w[First]
    @role.remove_permission! :edit_issue_tags

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      post :update, params: { ids: [1], issue: { tag_list: %w[First] }, mode: 'remove' }

      assert_equal I18n.t(:notice_failed_to_remove_tags), flash[:error]
      assert_equal %w[First], @issue_1.reload.tag_list
    end
  end

  # Without a chosen tag nothing is added or removed, so no issue is saved and no success is reported
  def test_add_or_remove_without_tags_changes_nothing
    @issue_1.update! tag_list: %w[First]

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      %w[append remove].each do |mode|
        assert_no_difference 'Journal.count', mode do
          post :update, params: { ids: [1, 2], issue: { tag_list: [''] }, mode: }
        end

        assert_redirected_to action: 'update'
        assert_nil flash[:notice], mode
        assert_equal %w[First], @issue_1.reload.tag_list, mode
      end
    end
  end
end
