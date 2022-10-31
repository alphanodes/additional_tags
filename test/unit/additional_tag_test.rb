# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class AdditionalTagTest < AdditionalTags::TestCase
  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :journals, :journal_details,
           :additional_tags, :additional_taggings

  def setup
    prepare_tests
    @project = projects :projects_001
  end

  def test_tag_name
    assert_equal 'Test1', AdditionalTag.new(name: 'Test1').tag_name
    assert_equal 'Test2', AdditionalTag.new(name: 'Test2::2').tag_name
    assert_equal 'Test3:2', AdditionalTag.new(name: 'Test3:2').tag_name
    assert_equal 'Test3 : 2', AdditionalTag.new(name: 'Test3 : 2').tag_name
    assert_equal 'Test4:sub', AdditionalTag.new(name: 'Test4:sub::2').tag_name
    assert_equal 'Test4::sub', AdditionalTag.new(name: 'Test4::sub::2').tag_name
  end

  def test_valid_mutually_exclusive_tag
    assert AdditionalTag.valid_mutually_exclusive_tag(%w[Foo::1 Bar::2 Test3])
    assert AdditionalTag.valid_mutually_exclusive_tag(%w[Foo::1 Foo::Bar::2 Test3])
    assert AdditionalTag.valid_mutually_exclusive_tag(['Foo:: 1', 'Bar::2', 'Test3'])
    assert AdditionalTag.valid_mutually_exclusive_tag(%w[Test3])
    assert AdditionalTag.valid_mutually_exclusive_tag(nil)
    assert AdditionalTag.valid_mutually_exclusive_tag(%w[])
  end

  def test_invalid_mutually_exclusive_tag
    assert_not AdditionalTag.valid_mutually_exclusive_tag(%w[Bar::2 Bar::3])
    assert_not AdditionalTag.valid_mutually_exclusive_tag(%w[Foo::1 Bar::2 Bar::3 Test3])
    assert_not AdditionalTag.valid_mutually_exclusive_tag(['Bar:: 2', 'Bar::3'])
    assert_not AdditionalTag.valid_mutually_exclusive_tag(['Bar :: 2', 'Bar::3'])
  end
end
