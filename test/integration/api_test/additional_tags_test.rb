# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__
module ApiTest
  class AdditionalTagsTest < AdditionalTags::ApiTest
    def setup
      super
      prepare_tests
    end

    def test_get_additional_tags_xml_should_contain_metadata
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/additional_tags.xml',
            params: { type: 'issue' },
            headers: credentials('admin')

        assert_response :success
        assert_select 'tags[total_count][tag_type="Issue"][type=array]'
      end
    end

    def test_get_additional_tags_json_should_list_tags
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/additional_tags.json',
            params: { type: 'issue' },
            headers: credentials('admin')

        assert_response :success
        tags = response.parsed_body

        assert_not_empty tags['tags']
        assert_equal 5, tags['tags'].size
        assert_sorted_equal %w[First Four Second Third five],
                            tags['tags'].pluck('name')
      end
    end

    def test_get_additional_tags_json_should_list_tags_of_a_project
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/additional_tags.json',
            params: { type: 'issue', project_id: 'onlinestore' },
            headers: credentials('admin')

        assert_response :success
        assert_equal %w[Second], response.parsed_body['tags'].pluck('name')
      end
    end

    def test_get_additional_tags_json_should_list_visible_tags_for_non_admins
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/additional_tags.json',
            params: { type: 'issue' },
            headers: credentials('dlopper', 'foo')

        assert_response :success
        # Only the tags of ecookbook, the project of the user
        assert_sorted_equal %w[First Four Second Third],
                            response.parsed_body['tags'].pluck('name')
      end
    end

    def test_get_additional_tags_json_should_not_find_invisible_project
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/additional_tags.json',
            params: { type: 'issue', project_id: 'onlinestore' },
            headers: credentials('dlopper', 'foo')

        assert_response :not_found
      end
    end

    def test_get_additional_tags_json_should_list_wiki_tags
      with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
        get '/additional_tags.json',
            params: { type: 'wiki' },
            headers: credentials('admin')

        assert_response :success
        assert_equal 'WikiPage', response.parsed_body['tag_type']
        assert_includes response.parsed_body['tags'].pluck('name'), 'First'
      end
    end

    def test_get_additional_tags_xml_should_reject_unsupported_type
      get '/additional_tags.xml',
          params: { type: 'does_not_exist' },
          headers: credentials('admin')

      assert_response :unprocessable_content
    end

    def test_get_additional_tags_json_should_require_login_if_configured
      with_settings login_required: '1' do
        with_plugin_settings 'additional_tags', active_issue_tags: 1 do
          get '/additional_tags.json', params: { type: 'issue' }

          assert_response :unauthorized
        end
      end
    end

    def test_get_additional_tags_xml_should_require_type
      get '/additional_tags.xml',
          headers: credentials('admin')

      assert_response :unprocessable_content
    end

    def test_get_additional_tags_json_should_list_type_without_visibility_for_admins_only
      with_admin_only_tag_type do
        get '/additional_tags.json',
            params: { type: 'admin_only' },
            headers: credentials('dlopper', 'foo')

        assert_response :forbidden

        get '/additional_tags.json',
            params: { type: 'admin_only' },
            headers: credentials('admin')

        assert_response :success
        assert_equal 'Issue', response.parsed_body['tag_type']
      end
    end

    private

    # Registers a tag type without respects_visibility, as a plugin does for
    # entities whose available_tags ignores the visibility of single entries.
    # The listener is removed again, so no other test sees the type.
    def with_admin_only_tag_type
      Redmine::Hook.add_listener AdminOnlyTagTypeListener
      yield
    ensure
      Redmine::Hook.class_variable_get(:@@listener_classes).delete AdminOnlyTagTypeListener
      Redmine::Hook.clear_listeners_instances
    end
  end

  # Not a Redmine::Hook::Listener: subclasses register themselves for all tests
  class AdminOnlyTagTypeListener
    include Singleton

    def helper_additional_manageable_tag_columns(context = {})
      context[:columns][:admin_only] = { label: 'Admin only', klass: Issue }
    end
  end
end
