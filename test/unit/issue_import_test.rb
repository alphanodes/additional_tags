# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueImportTest < AdditionalTags::TestCase
  def setup
    User.current = users :users_001
  end

  def test_tag_list_is_registered_in_auto_mappable_fields
    assert_equal 'field_tags', IssueImport::AUTO_MAPPABLE_FIELDS['tag_list']
  end

  def test_import_sets_tag_list_on_resulting_issues
    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      import = build_import_with_tags
      assert_difference 'Issue.count', 3 do
        import.run
      end

      saved = import.saved_objects.to_a

      assert_equal 3, saved.size
      assert_equal %w[First Second], saved[0].tag_list.to_a.sort
      assert_equal %w[Third],        saved[1].tag_list.to_a.sort
      assert_equal %w[First Third],  saved[2].tag_list.to_a.sort
    end
  end

  # The CSV value holds several tags, each of them has to be found among the existing tags
  def test_import_sets_existing_tags_with_permission_to_edit_tags_only
    prepare_tests
    roles(:roles_001).remove_permission! :create_issue_tags

    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      import = build_import_with_tags user_id: 2
      import.run

      assert_equal [%w[First Second], %w[Third], %w[First Third]], import.saved_objects.map(&:tag_list)
    end
  end

  def test_import_skips_blank_tag_list_values
    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      import = build_import_with_tags
      import.settings['mapping'].delete 'tag_list'
      import.save!

      assert_difference 'Issue.count', 3 do
        import.run
      end

      assert(import.saved_objects.all? { |i| i.tag_list.to_a.empty? })
    end
  end

  private

  def build_import_with_tags(user_id: 1)
    csv_path = File.expand_path '../../fixtures/files/import_issues_with_tags.csv', __FILE__
    import = IssueImport.new
    import.user_id = user_id
    import.file = Rack::Test::UploadedFile.new csv_path, 'text/csv', true
    import.save!
    import.settings = {
      'separator' => ';',
      'wrapper' => '"',
      'encoding' => 'UTF-8',
      'mapping' => {
        'project_id' => '1',
        'tracker' => '3',
        'subject' => '1',
        'description' => '2',
        'status' => '4',
        'tag_list' => '5'
      }
    }
    import.save!
    import
  end
end
