# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class AutoCompletesControllerTest < AdditionalTags::ControllerTest
  def setup
    prepare_tests
    @tag = ActsAsTaggableOn::Tag.find_by name: 'First'

    @request.session[:user_id] = 2
  end

  def test_issue_tags_should_not_be_case_sensitive
    get :issue_tags,
        params: { project_id: 'ecookbook', q: 'fir' }

    assert_response :success
    issue_tags = ActiveSupport::JSON.decode(response.body).pluck('id')

    assert_not_nil issue_tags
    assert_equal [@tag.name], issue_tags
  end

  def test_issue_tags_should_return_json
    get :issue_tags,
        params: { project_id: 'ecookbook', q: 'Fir' }

    assert_response :success
    json = ActiveSupport::JSON.decode response.body

    assert_kind_of Array, json
    parsed_tag = json.last

    assert_kind_of Hash, parsed_tag
    assert_equal @tag.name, parsed_tag['id']
    assert_equal @tag.name, parsed_tag['text']
  end

  def test_suggestion_order_default
    with_settings plugin_additional_tags: Setting.available_settings['plugin_additional_tags']['default'] do
      get :issue_tags,
          params: { project_id: 'ecookbook' }
    end

    assert_response :success
    tags = ActiveSupport::JSON.decode(response.body).pluck('id')

    assert_equal %w[First Four Second Third], tags
  end

  def test_suggestion_order_name
    with_plugin_settings 'additional_tags', tags_suggestion_order: 'name' do
      get :issue_tags,
          params: { project_id: 'ecookbook' }
    end

    assert_response :success
    tags = ActiveSupport::JSON.decode(response.body).pluck('id')

    assert_equal %w[First Four Second Third], tags
  end

  def test_suggestion_order_count
    with_plugin_settings 'additional_tags', tags_suggestion_order: 'count' do
      get :issue_tags,
          params: { project_id: 'ecookbook' }
    end

    assert_response :success
    tags = ActiveSupport::JSON.decode(response.body).pluck('id')

    assert_equal 'Second', tags.first
  end

  def test_suggestion_order_last_created
    with_plugin_settings 'additional_tags', tags_suggestion_order: 'last_created' do
      get :issue_tags,
          params: { project_id: 'ecookbook' }
    end

    assert_response :success
    tags = ActiveSupport::JSON.decode(response.body).pluck('id')

    assert_equal %w[First Third Four Second], tags
  end

  def test_wiki_tags_should_return_json
    get :wiki_tags,
        params: { project_id: 'onlinestore', q: 'Fir' }

    assert_response :success
    json = ActiveSupport::JSON.decode response.body

    assert_kind_of Array, json
    parsed_tag = json.last

    assert_kind_of Hash, parsed_tag
    assert_equal @tag.name, parsed_tag['id']
    assert_equal @tag.name, parsed_tag['text']
  end

  def test_all_tags_should_return_json
    @request.session[:user_id] = 1

    get :all_tags,
        params: { project_id: 'onlinestore', q: 'Fir' }

    assert_response :success
    json = ActiveSupport::JSON.decode response.body

    assert_kind_of Array, json
    parsed_tag = json.last

    assert_kind_of Hash, parsed_tag
    assert_equal @tag.name, parsed_tag['id']
    assert_equal @tag.name, parsed_tag['text']
  end

  def test_all_tags_forbidden_for_non_admins
    get :all_tags,
        params: { project_id: 'onlinestore', q: 'Fir' }

    assert_response :forbidden
  end
end
