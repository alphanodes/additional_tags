# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class AdditionalTagTest < AdditionalTags::TestCase
  def setup
    @project = projects :projects_001
  end

  def test_tag_name
    assert_equal 'Test1', AdditionalTag.new(name: 'Test1').tag_name
    assert_equal 'scoped', AdditionalTag.new(name: 'scoped::2').tag_name
    assert_equal 'Test3:2', AdditionalTag.new(name: 'Test3:2').tag_name
    assert_equal 'Test3 : 2', AdditionalTag.new(name: 'Test3 : 2').tag_name
    assert_equal 'scoped:sub', AdditionalTag.new(name: 'scoped:sub::2').tag_name
    assert_equal 'scoped::sub', AdditionalTag.new(name: 'scoped::sub::2').tag_name
  end

  def test_name_for_color
    assert_equal 'Test1', AdditionalTag.new(name: 'Test1', color_theme: nil).name_for_color
    assert_equal 'Test2', AdditionalTag.new(name: 'Test2', color_theme: '0').name_for_color
    assert_equal 'Test3', AdditionalTag.new(name: 'Test3', color_theme: '1').name_for_color
    assert_equal 'Test4a', AdditionalTag.new(name: 'Test4', color_theme: 'a').name_for_color
    assert_equal 'Test5b', AdditionalTag.new(name: 'Test5', color_theme: 'b').name_for_color
    assert_equal 'scoped::', AdditionalTag.new(name: 'scoped::1', color_theme: '1').name_for_color
    assert_equal 'scoped::a', AdditionalTag.new(name: 'scoped::2', color_theme: 'a').name_for_color
    assert_equal 'grouped:', AdditionalTag.new(name: 'grouped: 1', color_theme: '1').name_for_color
    assert_equal 'grouped:a', AdditionalTag.new(name: 'grouped: 2', color_theme: 'a').name_for_color
  end

  def test_valid_mutually_exclusive_tag
    assert AdditionalTag.mutually_exclusive_tags?(%w[Foo::1 Bar::2 Test3])
    assert AdditionalTag.mutually_exclusive_tags?(%w[Foo::1 Foo::Bar::2 Test3])
    assert AdditionalTag.mutually_exclusive_tags?(['Foo:: 1', 'Bar::2', 'Test3'])
    assert AdditionalTag.mutually_exclusive_tags?(%w[Test3])
    assert AdditionalTag.mutually_exclusive_tags?(nil)
    assert AdditionalTag.mutually_exclusive_tags?(%w[])
  end

  def test_invalid_mutually_exclusive_tag
    assert_not AdditionalTag.mutually_exclusive_tags?(%w[Bar::2 Bar::3])
    assert_not AdditionalTag.mutually_exclusive_tags?(%w[Foo::1 Bar::2 Bar::3 Test3])
    assert_not AdditionalTag.mutually_exclusive_tags?(['Bar:: 2', 'Bar::3'])
    assert_not AdditionalTag.mutually_exclusive_tags?(['Bar :: 2', 'Bar::3'])
  end

  def test_group_value
    assert_equal '2', AdditionalTag.new(name: 'scoped::2').group_value
    assert_equal '1', AdditionalTag.new(name: 'grouped: 1').group_value
    assert_equal 'Test1', AdditionalTag.new(name: 'Test1').group_value
  end

  def test_scoped
    assert AdditionalTag.new(name: 'scoped::2').scoped?
    assert_not AdditionalTag.new(name: 'grouped:1').scoped?
    assert_not AdditionalTag.new(name: 'plain').scoped?
  end

  def test_grouped
    assert AdditionalTag.new(name: 'grouped:1').grouped?
    assert_not AdditionalTag.new(name: 'plain').grouped?
  end

  def test_disable_grouping
    tag = AdditionalTag.new name: 'scoped::2', disable_grouping: true

    assert_not tag.scoped?
    assert_not tag.grouped?
  end

  def test_tag_bg_color_returns_hex
    tag = AdditionalTag.new name: 'test'

    assert_match(/\A#[0-9a-f]{6}\z/, tag.tag_bg_color)
  end

  def test_tag_fg_color_returns_black_or_white
    tag = AdditionalTag.new name: 'test'

    assert_includes %w[black white], tag.tag_fg_color
  end

  def test_tag_bg_color_with_custom_color
    tag = AdditionalTag.new name: 'test', bg_color: '#ff0000'

    assert_equal '#ff0000', tag.tag_bg_color
  end

  def test_all_type_tags_for_issues
    prepare_tests
    tags = AdditionalTag.all_type_tags Issue

    assert_kind_of ActiveRecord::Relation, tags
    assert tags.any?

    tag_names = tags.map(&:name)

    assert_includes tag_names, 'First'
  end

  def test_all_type_tags_returns_distinct
    prepare_tests
    tags = AdditionalTag.all_type_tags Issue

    ids = tags.map(&:id)
    ids.uniq!

    assert_equal ids.size, tags.size
  end

  def test_tag_to_joins_returns_join_array
    joins = AdditionalTag.tag_to_joins Issue

    assert_kind_of Array, joins
    assert_equal 2, joins.size
    assert_includes joins.first, AdditionalTagging.table_name
    assert_includes joins.second, AdditionalTag.table_name
  end

  def test_build_relation_tags_with_tagged_entries
    prepare_tests
    issue = issues :issues_001
    issue.tag_list = %w[rel_tag1 rel_tag2]

    assert_save issue

    tags = AdditionalTag.build_relation_tags issue

    assert_equal 2, tags.size
    assert_includes tags.map(&:name), 'rel_tag1'
  ensure
    AdditionalTag.where(name: %w[rel_tag1 rel_tag2]).find_each do |t|
      t.taggings.delete_all
      t.destroy
    end
  end

  def test_build_relation_tags_with_empty_entries
    assert_equal [], AdditionalTag.build_relation_tags([])
  end

  def test_build_relation_tags_with_multiple_entries
    prepare_tests
    issue1 = issues :issues_001
    issue2 = issues :issues_003
    issue1.tag_list = %w[shared_tag]

    assert_save issue1

    tags = AdditionalTag.build_relation_tags [issue1, issue2]

    tag_names = tags.map(&:name)

    assert_includes tag_names, 'shared_tag'
    assert_includes tag_names, 'Second'
  ensure
    t = AdditionalTag.find_by name: 'shared_tag'
    if t
      t.taggings.delete_all
      t.destroy
    end
  end

  def test_sort_tags_alphabetical_with_special_chars
    tags = %w[Über Apfel Birne]
    result = AdditionalTag.sort_tags tags

    assert_equal %w[Apfel Birne Über], result
  end

  def test_sort_tags_case_insensitive
    tags = %w[banana Apple cherry]
    result = AdditionalTag.sort_tags tags

    assert_equal %w[Apple banana cherry], result
  end

  def test_sort_tag_list_by_name
    tag_a = AdditionalTag.new name: 'Zebra'
    tag_b = AdditionalTag.new name: 'apple'
    result = AdditionalTag.sort_tag_list [tag_a, tag_b]

    assert_equal 'apple', result.first.name
    assert_equal 'Zebra', result.last.name
  end

  def test_subproject_sql
    sql = AdditionalTag.subproject_sql @project

    assert_includes sql, 'lft'
    assert_includes sql, 'rgt'
    assert_includes sql, @project.lft.to_s
    assert_includes sql, @project.rgt.to_s
  end

  def test_visible_condition_returns_sql
    prepare_tests
    user = users :users_002
    result = AdditionalTag.visible_condition user

    assert_kind_of String, result
    assert_includes result, 'id IN'
  end

  def test_visible_condition_with_no_permission_returns_no_result
    user = User.anonymous
    result = AdditionalTag.visible_condition user, permission: :non_existing_permission

    assert_kind_of String, result
  end
end
