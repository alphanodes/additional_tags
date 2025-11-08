# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueMacrosTest < AdditionalTags::ControllerTest
  include ActionView::Helpers::TextHelper
  include ERB::Util

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :enabled_modules, :issues, :trackers, :issue_statuses,
           :workflows, :enumerations

  def setup
    prepare_tests

    EnabledModule.create project_id: 1, name: 'wiki'
    @project = projects :projects_001
    setup_page
    setup_test_issues_with_tags
  end

  def test_issue_tag_macro
    text = '{{issue_tag(TestTag)}}'

    save_content text, 2
    @request.session[:user_id] = 2
    get :show,
        params: { project_id: 1, id: @page_name }

    assert_response :success
    assert_select 'ul.issue_tag'
  end

  def test_issue_tag_macro_with_title
    text = +"{{issue_tag(TestTag,title=Tagged issues)}}\n"
    text << "{{issue_tag(TestTag,title=Tagged issues, with_count=true)}}\n"

    save_content text, 2
    @request.session[:user_id] = 2
    get :show,
        params: { project_id: 1, id: @page_name }

    assert_response :success
    assert_select 'h3', /Tagged issues/
    assert_select 'h3', /\(1\)/ # with_count should show (1)
  end

  def test_issue_tag_macro_all_projects
    text = '{{issue_tag(TestTag, all_projects=true)}}'

    save_content text, 2
    @request.session[:user_id] = 2
    get :show,
        params: { project_id: 1, id: @page_name }

    assert_response :success
  end

  def test_issue_tag_count_macro
    text = '{{issue_tag_count(TestTag)}}'

    save_content text, 2
    @request.session[:user_id] = 2
    get :show,
        params: { project_id: 1, id: @page_name }

    assert_response :success
    assert_select 'div.wiki', /1/ # should show count of 1
  end

  def test_issue_tag_count_macro_all_projects
    text = '{{issue_tag_count(TestTag, all_projects=true)}}'

    save_content text, 2
    @request.session[:user_id] = 2
    get :show,
        params: { project_id: 1, id: @page_name }

    assert_response :success
  end

  def test_issue_tag_macro_with_no_data
    text = '{{issue_tag(NonExistentTag)}}'

    save_content text, 2
    @request.session[:user_id] = 2
    get :show,
        params: { project_id: 1, id: @page_name }

    assert_response :success
    assert_select 'div.no_entries'
  end

  private

  def setup_page
    @controller = WikiController.new
    @request.env['HTTP_REFERER'] = '/'
    @wiki = @project.wiki
    @page_name = 'macro_test'
    @page = @wiki.find_or_new_page @page_name
    @page.content = WikiContent.new
    @page.content.text = 'test'
    @page.save!
  end

  def save_content(text, author_id)
    page = @wiki.find_or_new_page @page_name
    page.content.text = text
    page.content.author_id = author_id

    assert_save page
    assert_save page.content
  end

  def setup_test_issues_with_tags
    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      issue = Issue.find 1
      issue.tag_list = ['TestTag']
      issue.save!
    end
  end
end
