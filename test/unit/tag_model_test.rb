# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TagModelTest < AdditionalTags::TestCase
  def test_table_name
    assert_equal 'additional_tags', AdditionalTag.table_name
  end

  def test_has_many_taggings
    tag = AdditionalTag.create! name: 'has_many_test'

    assert_respond_to tag, :taggings
  ensure
    tag&.destroy
  end

  def test_name_presence_required
    tag = AdditionalTag.new name: nil

    assert_not tag.valid?
    assert_includes tag.errors[:name], 'cannot be blank'
  end

  def test_name_presence_rejects_blank
    tag = AdditionalTag.new name: ''

    assert_not tag.valid?
    assert_includes tag.errors[:name], 'cannot be blank'
  end

  def test_name_uniqueness
    existing = AdditionalTag.create! name: 'unique_test'
    duplicate = AdditionalTag.new name: 'unique_test'

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], 'has already been taken'
  ensure
    existing&.destroy
  end

  def test_name_max_length
    tag = AdditionalTag.new name: 'a' * 256

    assert_not tag.valid?
    assert_includes tag.errors[:name], 'is too long (maximum is 255 characters)'
  end

  def test_name_at_max_length_is_valid
    tag = AdditionalTag.new name: 'a' * 255

    assert tag.valid?
  end

  def test_named_scope_finds_case_insensitive
    tag = AdditionalTag.create! name: 'CaseTest'

    assert_includes AdditionalTag.named('casetest'), tag
    assert_includes AdditionalTag.named('CaseTest'), tag
    assert_includes AdditionalTag.named('CASETEST'), tag
  ensure
    tag&.destroy
  end

  def test_named_scope_returns_empty_for_nonexistent
    assert_empty AdditionalTag.named('nonexistent_tag_xyz')
  end

  def test_named_any_scope_finds_multiple_tags
    tag1 = AdditionalTag.create! name: 'any_test_one'
    tag2 = AdditionalTag.create! name: 'any_test_two'
    result = AdditionalTag.named_any %w[any_test_one any_test_two]

    assert_includes result, tag1
    assert_includes result, tag2
  ensure
    tag1&.destroy
    tag2&.destroy
  end

  def test_named_any_scope_case_insensitive
    tag = AdditionalTag.create! name: 'AnyCase'
    result = AdditionalTag.named_any %w[anycase]

    assert_includes result, tag
  ensure
    tag&.destroy
  end

  def test_find_or_create_all_with_like_by_name_creates_new
    result = AdditionalTag.find_or_create_all_with_like_by_name 'brand_new_tag'

    assert_equal 1, result.size
    assert_equal 'brand_new_tag', result.first.name
  ensure
    AdditionalTag.where(name: 'brand_new_tag').destroy_all
  end

  def test_find_or_create_all_with_like_by_name_finds_existing
    existing = AdditionalTag.create! name: 'already_exists'
    result = AdditionalTag.find_or_create_all_with_like_by_name 'already_exists'

    assert_equal 1, result.size
    assert_equal existing.id, result.first.id
  ensure
    existing&.destroy
  end

  def test_find_or_create_all_with_like_by_name_mixed
    existing = AdditionalTag.create! name: 'existing_mix'
    result = AdditionalTag.find_or_create_all_with_like_by_name 'existing_mix', 'new_mix'

    assert_equal 2, result.size

    names = result.map(&:name)

    assert_includes names, 'existing_mix'
    assert_includes names, 'new_mix'
  ensure
    existing&.destroy
    AdditionalTag.where(name: 'new_mix').destroy_all
  end

  def test_find_or_create_all_with_like_by_name_no_duplicates_created
    existing = AdditionalTag.create! name: 'no_dup'
    count_before = AdditionalTag.where(name: 'no_dup').count
    AdditionalTag.find_or_create_all_with_like_by_name 'no_dup'

    assert_equal count_before, AdditionalTag.where(name: 'no_dup').count
  ensure
    existing&.destroy
  end

  def test_to_s_returns_name
    tag = AdditionalTag.new name: 'hello'

    assert_equal 'hello', tag.to_s
  end

  def test_count_returns_integer
    tag = AdditionalTag.new name: 'count_test'

    assert_kind_of Integer, tag.count
    assert_equal 0, tag.count
  end

  def test_equality_by_name
    tag_a = AdditionalTag.new name: 'same'
    tag_b = AdditionalTag.new name: 'same'

    assert_equal tag_a, tag_b
  end

  def test_inequality_by_name
    tag_a = AdditionalTag.new name: 'one'
    tag_b = AdditionalTag.new name: 'two'

    assert_not_equal tag_a, tag_b
  end
end
