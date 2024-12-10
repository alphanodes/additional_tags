# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class DashboardAsyncBlocksControllerTest < AdditionalTags::ControllerTest
  include Redmine::I18n

  def setup
    prepare_tests
    Setting.default_language = 'en'

    @project = projects :projects_001
    @welcome_dashboard = dashboards :system_default_welcome
    @project_dashboard = dashboards :system_default_project
  end

  def test_issue_tags_block_on_welcome
    @request.session[:user_id] = 2
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :show,
          params: { dashboard_id: @welcome_dashboard.id,
                    block: 'issue_tags',
                    format: 'js' }

      assert_response :success
      assert_select 'ul.tag-summary'
      assert_select 'li.amount-tags .value', text: /3/
      assert_select 'li.amount-entities-with-tags .value', text: /5/
      assert_select 'table.list.tags tbody tr', count: 3
    end
  end

  def test_issue_tags_block_on_project
    @request.session[:user_id] = 2
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :show,
          params: { dashboard_id: @project_dashboard.id,
                    block: 'issue_tags',
                    project_id: projects(:projects_002),
                    format: 'js' }

      assert_response :success
      assert_select 'ul.tag-summary'
      assert_select 'li.amount-tags .value', text: /1/
      assert_select 'li.amount-entities-with-tags .value', text: /1/
      assert_select 'table.list.tags tbody tr', count: 1
    end
  end

  def test_issue_tags_block_on_welcome_if_disabled
    @request.session[:user_id] = 2
    with_plugin_settings 'additional_tags', active_issue_tags: 0 do
      get :show,
          params: { dashboard_id: @welcome_dashboard.id,
                    block: 'issue_tags',
                    format: 'js' }

      assert_response :forbidden
    end
  end

  def test_issue_tags_block_on_project_if_disabled
    @request.session[:user_id] = 2
    with_plugin_settings 'additional_tags', active_issue_tags: 0 do
      get :show,
          params: { dashboard_id: @project_dashboard.id,
                    block: 'issue_tags',
                    project_id: projects(:projects_002),
                    format: 'js' }

      assert_response :forbidden
    end
  end
end
