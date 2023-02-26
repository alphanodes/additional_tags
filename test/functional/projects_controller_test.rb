# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class ProjectsControllerTest < AdditionalTags::ControllerTest
  fixtures :projects, :users,
           :roles, :members, :member_roles,
           :issues, :issue_statuses,
           :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules,
           :dashboards

  def setup
    User.current = nil
  end

  def test_show_with_blocks
    @request.session[:user_id] = 4
    get :show,
        params: { id: 1 }

    assert_response :success
    assert_select 'div#list-left div#block-projectinformation'
  end
end
