# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class WikiPageTest < AdditionalTags::TestCase
  fixtures :users, :email_addresses, :user_preferences,
           :roles, :members, :member_roles,
           :projects, :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :additional_tags, :additional_taggings

  def setup
    prepare_tests
    User.current = nil
    @wiki = wikis :wikis_001
    @page = @wiki.pages.first
  end

  def test_no_change_should_not_update_page
    User.current = users :users_002

    with_tags_settings active_wiki_tags: 1 do
      page = WikiPage.find_by title: 'Another_page'
      assert_no_difference 'WikiContentVersion.count' do
        assert_save page
      end
    end
  end

  def test_add_tag_should_not_create_new_version
    User.current = users :users_002

    with_tags_settings active_wiki_tags: 1 do
      page = WikiPage.find_by title: 'Another_page'
      assert_no_difference 'WikiContentVersion.count' do
        page.tag_list << 'Test1'
        assert_save page

        page.reload
        assert_equal %w[First Test1], page.tag_list.sort
      end
    end
  end
end
