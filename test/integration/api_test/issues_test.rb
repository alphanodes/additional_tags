# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__

module ApiTest
  class IssuesTest < AdditionalTags::ApiTest
    def setup
      super
      prepare_tests
    end

    test 'GET /issues.xml should contain metadata' do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/issues.xml', headers: credentials('jsmith')

        assert_select 'issues[type=array][total_count][limit="25"][offset="0"]'
      end
    end

    test 'GET /issues/:id.xml with tags' do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        get '/issues/1.xml', headers: credentials('jsmith')

        assert_select 'issue>tags'
        assert_select 'issue>tags', child: { tag: 'id', content: 'Four' }
      end
    end

    test 'GET /issues/:id.xml without tags if issue tags disabled' do
      with_plugin_settings 'additional_tags', active_issue_tags: 0 do
        get '/issues/1.xml', headers: credentials('jsmith')

        assert_select 'issue>tags', count: 0
      end
    end

    test 'POST /issues.json should create an issue with the tags' do
      payload = <<~JSON
        {
          "issue": {
            "project_id": "1",
            "tracker_id": "2",
            "status_id": "3",
            "subject": "API test",
            "tag_list": "cat, dog, mouse"
          }
        }
      JSON

      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        assert_difference 'Issue.count' do
          post '/issues.json',
               params: payload,
               headers: { 'CONTENT_TYPE' => 'application/json' }.merge(credentials('jsmith'))
        end

        issue = Issue.order(id: :desc).first

        assert_equal 1, issue.project_id
        assert_equal 'API test', issue.subject
        assert_sorted_equal %w[cat dog mouse], issue.tags.map(&:name)
      end
    end

    test 'PUT /issues/:id.xml with tags' do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        assert_difference 'Journal.count' do
          put '/issues/6.xml',
              params: { issue: { subject: 'API update',
                                 tag_list: 'cat, dog, mouse' } },
              headers: credentials('jsmith')

          assert_response :success
        end
        issue = Issue.find 6

        assert_equal 'API update', issue.subject
        assert_sorted_equal %w[cat dog mouse], issue.tags.map(&:name)
      end
    end

    test 'PUT /issues/:id.xml with existing tags' do
      with_plugin_settings 'additional_tags', active_issue_tags: 1 do
        assert_difference 'Journal.count' do
          put '/issues/1.xml',
              params: { issue: { subject: 'API update',
                                 tag_list: 'cat, dog, mouse' } },
              headers: credentials('jsmith')
        end
        issue = Issue.find 1

        assert_equal 'API update', issue.subject
        assert_sorted_equal %w[cat dog mouse], issue.tags.map(&:name)
      end
    end
  end
end
