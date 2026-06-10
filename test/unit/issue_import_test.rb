# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class IssueImportTest < AdditionalTags::TestCase
  def setup
    User.current = users :users_001
  end

  test 'tag_list is registered in AUTO_MAPPABLE_FIELDS' do
    assert_equal 'field_tags', IssueImport::AUTO_MAPPABLE_FIELDS['tag_list']
  end

  test 'import sets tag_list on resulting issues' do
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

  test 'import skips blank tag_list values' do
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

  def build_import_with_tags
    csv_path = File.expand_path '../../fixtures/files/import_issues_with_tags.csv', __FILE__
    import = IssueImport.new
    import.user_id = 1
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
