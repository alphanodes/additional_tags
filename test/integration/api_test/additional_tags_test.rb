# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__
module ApiTest
  class AdditionalTagsTest < AdditionalTags::ApiTest
    fixtures :projects, :users, :roles,
             :enabled_modules, :enumerations,
             :projects, :projects_trackers, :enabled_modules,
             :members, :member_roles,
             :issues, :issue_statuses, :issue_categories,
             :additional_tags, :additional_taggings

    include AdditionalTags::TestHelper

    def setup
      super
      prepare_tests
    end

    test 'GET /additional_tags.xml should contain metadata' do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/additional_tags.xml',
            params: { type: 'issue' },
            headers: credentials('admin')

        assert_response :success
        assert_select 'tags[total_count][tag_type="Issue"][type=array]'
      end
    end

    test 'GET /additional_tags.json should list tags' do
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

    test 'GET /additional_tags.xml should require type' do
      get '/additional_tags.xml',
          headers: credentials('admin')

      assert_response :internal_server_error
    end
  end
end
