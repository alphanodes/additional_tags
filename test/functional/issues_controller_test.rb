# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssuesControllerTest < AdditionalTags::ControllerTest
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
           :time_entries,
           :journals, :journal_details,
           :queries,
           :additional_tags, :additional_taggings

  include Redmine::I18n

  def setup
    prepare_tests
    User.current = nil
  end

  def test_index_displays_tags_as_html_in_the_correct_column
    @request.session[:user_id] = 2

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      with_settings issue_list_default_columns: ['tags'] do
        get :index
      end
    end

    assert_response :success

    assert_select 'table.issues' do
      assert_select 'thead' do
        assert_select 'th', text: 'Tags'
      end

      assert_select 'tbody' do
        assert_select 'tr' do
          assert_select 'td.tags' do
            assert_select 'span.additional-tag-label-color' do
              assert_select 'a'
            end
          end
        end
      end
    end
  end

  def test_show_issue_should_not_display_tags_if_disabled
    with_plugin_settings 'additional_tags', active_issue_tags: '0' do
      @request.session[:user_id] = 2
      get :show, params: {
        id: 1
      }
    end

    assert_response :success
    assert_select 'div.tags', 0
  end

  def test_show_issue_should_display_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      get :show, params: {
        id: 1
      }
    end

    assert_response :success
    assert_select 'div.tags' do
      assert_select 'span.additional-tag-label-color a', 1
      assert_select 'span.additional-tag-label-color a', text: 'First'
    end
  end

  def test_show_issue_should_display_multiple_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      get :show, params: {
        id: 6
      }
    end

    assert_response :success

    assert_select 'div#tags-data' do
      assert_select 'span.additional-tag-label-color', 2, :text
      assert_select 'span.additional-tag-label-color a', text: 'Four'
      assert_select 'span.additional-tag-label-color a', text: 'Second'
    end

    assert_select 'select#issue_tag_list_show' do
      assert_select 'option[value="Four"][selected=selected]'
      assert_select 'option[value="Second"][selected=selected]'
    end
  end

  def test_show_issue_should_display_contrast_tag_colors
    with_plugin_settings 'additional_tags', active_issue_tags: 1,
                                            use_colors: 1 do
      @request.session[:user_id] = 2
      get :show, params: {
        id: 6
      }
    end

    assert_response :success

    assert_select 'div#tags-data' do
      assert_select 'span.additional-tag-label-color', 2, :text
      assert_select 'span.additional-tag-label-color[style*=?]', 'color: black', text: 'Four'
      assert_select 'span.additional-tag-label-color[style*=?]', 'background-color: #12f5ae', text: 'Four'
      assert_select 'span.additional-tag-label-color[style*=?]', 'color: black', text: 'Second'
      assert_select 'span.additional-tag-label-color[style*=?]', 'background-color: #8b88a8', text: 'Second'
    end

    assert_select 'select#issue_tag_list_show' do
      assert_select 'option[value="Four"][selected=selected]'
      assert_select 'option[value="Second"][selected=selected]'
    end
  end

  def test_should_create_ticket_with_tags
    @request.session[:user_id] = 2
    project = projects :projects_001
    assert_difference 'Issue.count' do
      post :create,
           params: { issue: { tracker_id: 3,
                              subject: 'test with tags',
                              project_id: 1,
                              status_id: 2,
                              priority_id: 5,
                              tag_list: ['cat, dog, mouse'] },
                     project_id: project }
    end

    last_issue = Issue.last

    assert_redirected_to controller: 'issues', action: 'show', id: last_issue.id
    assert_equal 'test with tags', last_issue.subject
    assert_sorted_equal %w[cat dog mouse], last_issue.tags.map(&:name)
  end

  def test_edit_issue_tags_should_journalize_changes
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2

      put :update, params: {
        id: 3, issue: { tag_list: ['First'] }
      }

      assert_redirected_to action: 'show', id: '3'

      issue = Issue.find 3
      journals = issue.journals
      journal_details = journals.first.details

      assert_equal ['First'], issue.tag_list
      assert_equal 1, journals.count
      assert_equal 1, journal_details.count
      assert_equal 'Second', journal_details.first.old_value
      assert_equal 'First', journal_details.first.value
    end
  end

  def test_bulk_edit_without_tag_list
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2

      issue1 = issues :issues_001
      issue1.tag_list << 'new_for_issue1'
      issue1.save!

      issue2 = issues :issues_002
      issue2.fixed_version_id = nil # remove it, because it cannot be saved otherwise
      issue2.tag_list << 'new_for_issue2'
      issue2.save!

      assert_equal %w[First new_for_issue1], issue1.reload.tag_list
      assert_equal %w[new_for_issue2], issue2.reload.tag_list

      post :bulk_update,
           params: { ids: [1, 2],
                     issue: { project_id: '', tracker_id: '' } }

      assert_response :redirect
      assert_equal %w[First new_for_issue1], Issue.find(1).tag_list
      assert_equal %w[new_for_issue2], Issue.find(2).tag_list
    end
  end

  def test_bulk_edit_with_empty_string_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 3
      issue1 = issues :issues_001
      issue2 = issues :issues_002

      assert_equal ['First'], issue1.tag_list
      assert issue2.tag_list.is_a? Array
      assert_empty issue2.tag_list

      post :bulk_update,
           params: { ids: [issue1.id, issue2.id],
                     issue: { project_id: '', tracker_id: '', tag_list: ['', ''] } }

      assert_response :redirect
      assert_equal ['First'], Issue.find(1).tag_list
      assert_empty Issue.find(2).tag_list
    end
  end

  def test_bulk_copy
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      issue1 = issues :issues_001
      issue1.tag_list << 'new_for_issue1'
      issue1.save!

      issue2 = issues :issues_002
      issue2.fixed_version_id = nil # remove it, because it cannot be saved otherwise
      issue2.save!

      assert_equal %w[First new_for_issue1], issue1.reload.tag_list
      assert_empty issue2.tag_list

      post :bulk_update,
           params: { ids: [issue1.id, issue2.id],
                     issue: { project_id: '', tracker_id: '', tag_list: ['bulk_tag'] },
                     copy: '1' }

      assert_response :redirect

      new_issue1 = Issue.where.not(id: 1).find_by subject: 'Cannot print recipes'
      new_issue2 = Issue.where.not(id: 2).find_by subject: 'Add ingredients categories'

      assert_equal %w[bulk_tag First new_for_issue1], new_issue1.tag_list
      assert_equal %w[bulk_tag], new_issue2.tag_list
    end
  end

  def test_bulk_copy_removal_of_shared_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 1
      issue1 = issues :issues_001
      issue1.tag_list << 'a_common_tag'
      issue1.save!

      issue2 = issues :issues_002
      issue2.fixed_version_id = nil # remove it, because it cannot be saved otherwise
      issue2.tag_list << 'a_common_tag'
      issue2.save!

      assert_equal %w[First a_common_tag], issue1.reload.tag_list
      assert_equal %w[a_common_tag], issue2.reload.tag_list

      # Removing 'a_common_tag'
      post :bulk_update,
           params: { ids: [issue1.id, issue2.id],
                     common_tags: Issue.common_tag_list_from_issues([issue1.id, issue2.id]).to_s,
                     issue: { project_id: '', tracker_id: '', tag_list: [''] },
                     copy: '1' }

      assert_response :redirect

      new_issue1 = Issue.where.not(id: 1).find_by subject: 'Cannot print recipes'
      new_issue2 = Issue.where.not(id: 2).find_by subject: 'Add ingredients categories'

      assert_equal %w[First], new_issue1.tag_list
      assert_empty new_issue2.tag_list
    end
  end

  def test_bulk_edit_with_changed_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      issue1 = issues :issues_001
      issue1.tag_list << 'new_for_issue1'
      issue1.save!

      issue2 = issues :issues_002
      issue2.fixed_version_id = nil # remove it, because it cannot be saved otherwise
      issue2.tag_list << 'new_for_issue2'
      issue2.save!

      assert_equal %w[First new_for_issue1], issue1.reload.tag_list
      assert_equal %w[new_for_issue2], issue2.reload.tag_list

      post :bulk_update,
           params: { ids: [issue1.id, issue2.id],
                     issue: { project_id: '', tracker_id: '', tag_list: ['bulk_tag'] } }

      assert_response :redirect

      assert_equal %w[bulk_tag First new_for_issue1], Issue.find(1).tag_list
      assert_equal %w[bulk_tag new_for_issue2], Issue.find(2).tag_list
    end
  end

  def test_bulk_edit_removal_of_shared_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      issue1 = issues :issues_001
      issue1.tag_list << 'a_common_tag'
      issue1.save!

      issue2 = issues :issues_002
      issue2.fixed_version_id = nil # remove it, because it cannot be saved otherwise
      issue2.tag_list << 'a_common_tag'
      issue2.save!

      assert_equal %w[First a_common_tag], issue1.reload.tag_list
      assert_equal %w[a_common_tag], issue2.reload.tag_list

      # Removing 'a_common_tag'
      post :bulk_update,
           params: { ids: [issue1.id, issue2.id],
                     common_tags: Issue.common_tag_list_from_issues([issue1.id, issue2.id]).to_s,
                     issue: { project_id: '', tracker_id: '', tag_list: [''] } }

      assert_response :redirect

      # Reset ActsAsTaggableOn::TagList cache
      issue1.remove_instance_variable :@tag_list
      issue2.remove_instance_variable :@tag_list

      assert_equal %w[First], issue1.tag_list
      assert_empty issue2.tag_list
    end
  end

  def test_new_with_permission_edit_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 3
      get :new,
          params: { issue: { project_id: 1 } }

      assert_select '#issue_tags'
    end
  end

  def test_new_without_permission_edit_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 7
      get :new,
          params: { issue: { project_id: 1 } }

      assert_select '#issue_tags', 0
    end
  end

  def test_new_with_permission_edit_tags_in_other_project
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      get :new,
          params: { issue: { project_id: 3 } }

      assert_select '#issue_tags', 0
    end
  end

  def test_edit_with_permission_edit_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      # User(id: 2) has role Manager in Project(id: 1) and Project(id: 1) contains Issue(id: 1)
      @request.session[:user_id] = 2
      manager_role = Role.find 1
      manager_role.add_permission! :edit_tags
      get :edit,
          params: { id: 1, issue: { project_id: 1 } }

      assert_select '#issue_tags'
    end
  end

  def test_edit_without_permission_edit_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 7
      get :edit,
          params: { id: 1, issue: { project_id: 1 } }

      assert_select '#issue_tags', 0
    end
  end

  def test_edit_tags_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      user = users :users_003
      @request.session[:user_id] = user.id
      tag = 'First'

      assert_not_equal Issue.find(2).tag_list, [tag]
      assert_includes Issue.available_tags(user: user).map(&:name), tag
      post :update,
           params: { id: 2, issue: { project_id: 1, tag_list: [tag] } }

      assert_response :redirect
      assert_equal Issue.find(2).tag_list, [tag]
    end
  end

  def test_do_not_edit_tags_without_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      user = users :users_007
      @request.session[:user_id] = user.id
      new_tag = 'Second'

      issue = issues :issues_001

      assert_includes Issue.available_tags(user: users(:users_001)).map(&:name), new_tag
      assert_not_includes Issue.available_tags(user: user).map(&:name), new_tag
      assert_equal 'Unable to print recipes', issue.description
      assert_not issue.tag_list.include?(new_tag)

      post :update,
           params: { id: issue.id,
                     issue: { project_id: 1,
                              description: 'New description',
                              tag_list: [new_tag] } }

      issue.reload

      assert_response :redirect
      assert_equal 'New description', issue.description
      assert_not issue.tag_list.include?(new_tag)
    end
  end

  def test_create_tags_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      new_tag = 'enable_create_tags_permission'

      assert_not_equal Issue.find(1).tag_list, [new_tag]
      # The project should not contain the new tag
      assert_not Issue.all_tags.map(&:name).include?(new_tag)
      post :update,
           params: { id: 1,
                     issue: { project_id: 1, tag_list: [new_tag] } }

      assert_response :redirect
      assert_equal [new_tag], Issue.find(1).tag_list
    end
  end

  def test_do_not_create_tags_without_permission
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 3
      new_tag = 'not_allowed'

      issue = issues :issues_001

      assert_not Issue.all_tags.map(&:name).include?(new_tag)
      assert_equal 'Unable to print recipes', issue.description
      assert_not issue.tag_list.include?(new_tag)

      post :update,
           params: { id: issue.id,
                     issue: { project_id: 1,
                              description: 'New description',
                              tag_list: [new_tag] } }

      issue.reload

      assert_response :redirect
      assert_equal 'New description', issue.description
      assert_not issue.tag_list.include?(new_tag)
    end
  end

  def test_filter_by_tag
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 1
      get :index,
          params: { project_id: 1,
                    set_filter: 1,
                    c: ['tags'],
                    f: ['tags'],
                    op: { 'tags' => '=' },
                    v: { 'tags' => %w[First Second] } }

      assert_response :success
      assert_select 'table.issues td.tags'
      assert_select 'table.issues td.tags span.additional-tag-label-color'
      assert_select 'tr#issue-1'
    end
  end

  def test_filter_by_tag_with_not
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 1
      get :index,
          params: { project_id: 1,
                    set_filter: 1,
                    c: ['tags'],
                    f: ['tags'],
                    op: { 'tags' => '!' },
                    v: { 'tags' => %w[First Second] } }

      assert_response :success
      assert_select 'table.issues td.tags'
      assert_select 'tr#issue-1', count: 0
      assert_select 'tr#issue-2', count: 1
    end
  end

  def test_filter_by_tag_with_none
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 1
      get :index,
          params: { project_id: 1,
                    set_filter: 1,
                    c: ['tags'],
                    f: ['tags'],
                    op: { 'tags' => '!*' } }

      assert_response :success
      assert_select 'table.issues td.tags'
      assert_select 'tr#issue-1', count: 0
      assert_select 'tr#issue-2'
    end
  end

  def test_filter_by_tag_with_all
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 1
      get :index,
          params: { project_id: 1,
                    set_filter: 1,
                    c: ['tags'],
                    f: ['tags'],
                    op: { 'tags' => '*' } }

      assert_response :success
      assert_select 'table.issues td.tags'
      assert_select 'tr#issue-1'
      assert_select 'tr#issue-2', count: 0
    end
  end

  def test_tag_column_should_not_contain_tags_if_user_has_no_permission
    roles(:roles_003).remove_permission! :view_issue_tags
    User.add_to_project users(:users_002), projects(:projects_003), roles(:roles_003)

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      @request.session[:user_id] = 2
      get :index,
          params: { project_id: 1,
                    set_filter: 1,
                    c: ['tags'],
                    f: ['tags'] }

      assert_response :success

      # User has no permission to view_issue_tags in this project
      assert_select 'tr#issue-5' do
        assert_select '.tags a', count: 0
      end
    end
  end
end
