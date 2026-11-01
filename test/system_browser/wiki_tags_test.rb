# frozen_string_literal: true

require File.expand_path '../../system_test_helper', __FILE__

module AdditionalTags
  class WikiTagsTest < SystemTestCase
    def setup
      super
      log_user 'jsmith', 'jsmith'
    end

    def test_wiki_page_creates_a_tag_typed_in
      with_tags_settings active_wiki_tags: '1' do
        visit '/projects/ecookbook/wiki/Another_page/edit'
        add_new_tag '#wiki_tags', 'Wiki fresh'
        find('#wiki_form input[name=commit]').click

        # Saving a wiki page shows no notice, it returns to the page
        assert_current_path '/projects/ecookbook/wiki/Another_page'
        assert_includes wiki_pages(:wiki_pages_002).reload.tag_list, 'Wiki fresh'
      end
    end
  end
end
