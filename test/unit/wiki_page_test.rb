# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class WikiPageTest < AdditionalTags::TestCase
  def setup
    prepare_tests
    @wiki = wikis :wikis_001
    @page = @wiki.pages.order(:id).first
  end

  def test_no_change_should_not_update_page
    User.current = users :users_002

    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      page = WikiPage.find_by title: 'Another_page'
      assert_no_difference 'WikiContentVersion.count' do
        assert_save page
      end
    end
  end

  def test_add_tag_should_not_create_new_version
    User.current = users :users_002

    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      page = WikiPage.find_by title: 'Another_page'
      assert_no_difference 'WikiContentVersion.count' do
        page.tag_list << 'Test1'

        assert_save page

        page.reload

        assert_sorted_equal %w[First Test1], page.tag_list
      end
    end
  end

  # safe_attributes= is the mass assignment gate: our patch has to pass the
  # attributes on to core, not just consume the tag_list.
  def test_safe_attributes_assigns_core_attributes
    User.current = users :users_002

    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      page = WikiPage.find_by title: 'Another_page'
      page.safe_attributes = { 'title' => 'Renamed_page' }

      assert_equal 'Renamed_page', page.title
    end
  end

  # Tags reach the page through the same call, and an unchanged list must not
  # be handed to core as an attribute.
  def test_safe_attributes_assigns_tags_alongside_core_attributes
    User.current = users :users_002
    Role.find(1).add_permission! :add_wiki_tags

    with_plugin_settings 'additional_tags', active_wiki_tags: 1 do
      page = WikiPage.find_by title: 'Another_page'
      # params arrive as HashWithIndifferentAccess, and the patch looks up :tag_list
      page.safe_attributes = { title: 'Tagged_page', tag_list: %w[First Second] }.with_indifferent_access

      assert_equal 'Tagged_page', page.title
      assert_sorted_equal %w[First Second], page.tag_list
    end
  end

  def test_with_tags_with_nil
    assert_empty WikiPage.with_tags(nil)
  end

  def test_with_tags_with_non_existing_tag
    assert_empty WikiPage.with_tags('non-existing-tag')
  end

  def test_with_tags_with_existing_tag
    User.current = users :users_002

    assert_equal 3, WikiPage.with_tags('First').count
  end

  def test_with_tags_mulitple_tags
    User.current = users :users_002

    assert_equal 3, WikiPage.with_tags(%w[First Second]).count
  end

  def test_with_tags_order_by_date
    User.current = users :users_002

    assert_equal 3, WikiPage.with_tags('First', order: 'date_desc').count
  end

  def test_with_tags_scope
    User.current = users :users_002

    assert_equal 12, WikiPage.with_tags_scope.count
  end

  def test_with_tags_scope_for_project
    User.current = users :users_002

    assert_equal 4, WikiPage.with_tags_scope(project: projects(:projects_002)).count
  end
end
