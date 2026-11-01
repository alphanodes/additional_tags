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
        choose_tag_suggestion '#issue_tags', 'Sec', 'Second'
        find('#issue-form input[name=commit]').click

        assert_selector '#flash_notice'
        within('.issue .tags') { assert_text 'Second' }
      end
    end
  end
end
