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

  def test_sort_tags_with_tag_objects
    tag_a = AdditionalTag.new name: 'Zebra'
    tag_b = AdditionalTag.new name: 'apple'
    result = AdditionalTag.sort_tags [tag_a, tag_b]

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

  def test_consolidate_case_duplicates_merges_taggings_onto_canonical
    # Setup requires case-sensitive tag-name uniqueness so "Foo" and "foo" can
    # coexist before the merge. MySQL uses utf8mb4_unicode_ci after
    # FixTagsCollation, which makes the setup impossible there.
    skip 'requires case-sensitive name uniqueness' if Redmine::Database.mysql?

    canonical = AdditionalTag.create! name: 'Foo'
    duplicate = AdditionalTag.create! name: 'foo'
    keep_tagging = AdditionalTagging.create! tag_id: canonical.id, taggable_id: 1, taggable_type: 'Issue'
    AdditionalTagging.create! tag_id: duplicate.id, taggable_id: 1, taggable_type: 'Issue'
    AdditionalTagging.create! tag_id: duplicate.id, taggable_id: 2, taggable_type: 'Issue'

    AdditionalTag.consolidate_case_duplicates!

    assert_nil AdditionalTag.find_by(id: duplicate.id)
    assert AdditionalTag.exists?(id: canonical.id)

    canonical_taggings = AdditionalTagging.where tag_id: canonical.id, taggable_type: 'Issue'

    assert_equal [1, 2], canonical_taggings.order(:taggable_id).pluck(:taggable_id)
    assert AdditionalTagging.exists?(id: keep_tagging.id)
    assert_equal 2, canonical.reload.taggings_count
  end

  def test_consolidate_case_duplicates_is_noop_without_duplicates
    before_tags = AdditionalTag.pluck(:id).sort
    before_taggings = AdditionalTagging.pluck(:id).sort

    AdditionalTag.consolidate_case_duplicates!

    assert_equal before_tags, AdditionalTag.pluck(:id).sort
    assert_equal before_taggings, AdditionalTagging.pluck(:id).sort
  end

  def test_consolidate_case_duplicates_with_three_variant_casings
    # Three tags with the same LOWER(name) - must all collapse onto the one
    # with the lowest id, with all distinct taggings preserved.
    skip 'requires case-sensitive name uniqueness' if Redmine::Database.mysql?

    canonical = AdditionalTag.create! name: 'Foo'
    dup_lower = AdditionalTag.create! name: 'foo'
    dup_upper = AdditionalTag.create! name: 'FOO'

    AdditionalTagging.create! tag_id: canonical.id, taggable_id: 1, taggable_type: 'Issue'
    AdditionalTagging.create! tag_id: dup_lower.id, taggable_id: 2, taggable_type: 'Issue'
    AdditionalTagging.create! tag_id: dup_upper.id, taggable_id: 3, taggable_type: 'Issue'

    AdditionalTag.consolidate_case_duplicates!

    # Only the canonical tag survives.
    assert AdditionalTag.exists?(id: canonical.id)
    assert_nil AdditionalTag.find_by(id: dup_lower.id)
    assert_nil AdditionalTag.find_by(id: dup_upper.id)

    canonical_taggings = AdditionalTagging.where(tag_id: canonical.id, taggable_type: 'Issue')
                                          .order(:taggable_id)
                                          .pluck(:taggable_id)

    assert_equal [1, 2, 3], canonical_taggings
    assert_equal 3, canonical.reload.taggings_count
  end

  def test_consolidate_case_duplicates_resets_counter_cache_after_dropping_conflicting_taggings
    # When several duplicate-tags share the same taggable_id (so the conflicting
    # taggings get dropped instead of reassigned), the counter cache on the
    # canonical tag must still reflect the actual remaining tagging count.
    skip 'requires case-sensitive name uniqueness' if Redmine::Database.mysql?

    canonical = AdditionalTag.create! name: 'Bar'
    duplicate = AdditionalTag.create! name: 'BAR'

    # Both tagged on issue 1 (conflict - the duplicate's tagging will be dropped).
    AdditionalTagging.create! tag_id: canonical.id, taggable_id: 1, taggable_type: 'Issue'
    AdditionalTagging.create! tag_id: duplicate.id, taggable_id: 1, taggable_type: 'Issue'
    # Only duplicate tagged on issue 2 (no conflict - tagging will be reassigned).
    AdditionalTagging.create! tag_id: duplicate.id, taggable_id: 2, taggable_type: 'Issue'

    AdditionalTag.consolidate_case_duplicates!

    # 2 unique (tag_id, taggable_id) combinations remain - issue 1 and issue 2.
    canonical.reload

    assert_equal 2, canonical.taggings.count, 'real count'
    assert_equal 2, canonical.taggings_count, 'counter cache must match real count'
  end

  def test_consolidate_case_duplicates_skips_null_and_empty_names
    # Tags with NULL or empty names must not be merged with each other (their
    # LOWER(name) is NULL or '', the model never produces them legitimately,
    # and they are cleaned up by the migration's defensive DELETE pass).
    canonical = AdditionalTag.create! name: 'Baz'

    # Bypass model validation to create rows that the model would reject.
    # We then verify consolidate_case_duplicates! does not touch them.
    empty_tag = AdditionalTag.new name: ''
    empty_tag.save validate: false

    before_canonical_id = canonical.id
    before_empty_id = empty_tag.id

    AdditionalTag.consolidate_case_duplicates!

    assert AdditionalTag.exists?(id: before_canonical_id), 'canonical must survive'
    assert AdditionalTag.exists?(id: before_empty_id), 'empty-name tag must not be merged'
  ensure
    empty_tag&.destroy
  end
end
