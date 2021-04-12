# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class ReportsControllerTest < AdditionalTags::ControllerTest
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
           :time_entries,
           :additional_tags, :additional_taggings

  def setup
    prepare_tests
    @request.session[:user_id] = 2
    @project = projects :projects_001
  end

  def test_get_report_with_tags
    with_tags_settings active_issue_tags: 1 do
      get :issue_report,
          params: { id: @project.id }

      assert_response :success
      assert_select '.splitcontentright h3', text: /Tags/
    end
  end

  def test_get_issue_report_details_with_tags
    with_tags_settings active_issue_tags: 1 do
      get :issue_report_details,
          params: { id: @project.id, detail: 'tag' }

      assert_response :success
      assert_select '#content h3', text: /Tags/
    end
  end

  def test_do_not_get_issue_report_details_with_tags_if_disabled
    with_tags_settings active_issue_tags: 0 do
      get :issue_report_details,
          params: { id: @project.id, detail: 'tag' }

      assert_response :missing
    end
  end
end
