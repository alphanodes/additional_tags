# frozen_string_literal: true

require File.expand_path '../../system_test_helper', __FILE__

module AdditionalTags
  class IssueTagsTest < SystemTestCase
    def setup
      super
      log_user 'jsmith', 'jsmith'
    end

    def test_new_issue_takes_a_tag_from_the_suggestions
      with_tags_settings active_issue_tags: '1' do
        visit '/projects/ecookbook/issues/new'
        fill_in 'issue_subject', with: 'Tagged from the suggestions'
        choose_select_entry '#issue_tags', 'Second', search: 'Sec'
        find('#issue-form input[name=commit]').click

        assert_selector '#flash_notice'
        within('.issue .tags') { assert_text 'Second' }
      end
    end

    def test_new_issue_creates_a_tag_typed_in
      with_tags_settings active_issue_tags: '1' do
        visit '/projects/ecookbook/issues/new'
        fill_in 'issue_subject', with: 'Tagged with a new tag'
        add_select_tag '#issue_tags', 'Brand new'
        find('#issue-form input[name=commit]').click

        assert_selector '#flash_notice'
        within('.issue .tags') { assert_text 'Brand new' }
      end
    end

    # A tag with a scope (group::value) replaces the tag of the same group
    def test_scoped_tag_replaces_the_tag_of_its_group
      issue = issues :issues_001
      issue.tag_list = 'Prio::Low'
      issue.save!

      with_tags_settings active_issue_tags: '1' do
        visit "/issues/#{issue.id}"
        # The edit link only shows while the pointer is over the tags
        find('#tags-data').hover
        find('#edit-tags-link').click
        add_select_tag '#edit-tags-form', 'Prio::High'
        find('#edit-tags-form input[type=submit]').click

        assert_selector '#flash_notice'
        assert_equal ['Prio::High'], issue.reload.tag_list
      end
    end

    def test_bulk_edit_adds_a_tag_to_all_issues
      with_tags_settings active_issue_tags: '1' do
        visit '/issues/bulk_edit?ids[]=1&ids[]=2'
        add_select_tag '#issue_tags', 'Bulk tag'
        find('#bulk_edit_form input[name=commit]').click

        assert_selector '#flash_notice'
        assert_includes issues(:issues_001).reload.tag_list, 'Bulk tag'
        assert_includes issues(:issues_002).reload.tag_list, 'Bulk tag'
      end
    end

    def test_context_menu_adds_a_tag_in_the_dialog
      with_tags_settings active_issue_tags: '1' do
        visit '/projects/ecookbook/issues'
        find('tr#issue-1 td.subject').right_click
        find('#context-menu a.icon-tags').hover
        find('#context-menu a[href*="mode=append"]').click

        within '#ajax-modal' do
          choose_select_entry '#issue_tags', 'Third', search: 'Thi'
          find('input[type=submit]').click
        end

        assert_no_selector '#ajax-modal', visible: true
        assert_includes issues(:issues_001).reload.tag_list, 'Third'
      end
    end
  end
end
