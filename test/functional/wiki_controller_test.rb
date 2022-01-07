# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class WikiControllerTest < AdditionalTags::ControllerTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :enabled_modules, :wikis, :wiki_pages, :wiki_contents,
           :wiki_content_versions, :attachments,
           :issues, :issue_statuses, :trackers,
           :additional_tags, :additional_taggings

  def setup
    prepare_tests
    User.current = nil
  end

  def test_update_page_without_changes_should_not_create_content_version
    @request.session[:user_id] = 2
    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      assert_no_difference 'WikiContentVersion.count' do
        put :update,
            params: { project_id: 1,
                      id: 'Another_page',
                      content: { comments: '',
                                 text: Wiki.find(1).find_page('Another_page').content.text,
                                 version: 1 },
                      wiki_page: { tag_list: ['First'] } }
      end
    end

    page = Wiki.find(1).pages.find_by(title: 'Another_page')
    assert_equal 1, page.content.version
    assert_equal ['First'], page.tag_list
  end

  def test_update_page_with_changes_should_create_content_version
    @request.session[:user_id] = 2
    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      assert_difference 'WikiContentVersion.count' do
        put :update,
            params: { project_id: 1,
                      id: 'Another_page',
                      content: { comments: '',
                                 text: 'new text',
                                 version: 1 },
                      wiki_page: { tag_list: ['test10'] } }
      end
    end

    page = Wiki.find(1).pages.find_by(title: 'Another_page')
    assert_equal 2, page.content.version
    assert_equal ['test10'], page.tag_list
  end

  def test_update_page_should_not_save_tags_without_permission
    @request.session[:user_id] = 3
    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      assert_no_difference 'WikiContentVersion.count' do
        put :update,
            params: { project_id: 1,
                      id: 'Another_page',
                      content: { comments: '',
                                 text: Wiki.find(1).find_page('Another_page').content.text,
                                 version: 1 },
                      wiki_page: { tag_list: ['New'] } }
      end
    end

    page = Wiki.find(1).pages.find_by(title: 'Another_page')
    assert_equal 1, page.content.version
    assert_equal ['First'], page.tag_list
  end
end
