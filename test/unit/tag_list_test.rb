# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TagListTest < AdditionalTags::TestCase
  def test_new_creates_empty_list
    tag_list = AdditionalTags::TagList.new

    assert_empty tag_list
    assert_kind_of Array, tag_list
  end

  def test_new_with_arguments
    tag_list = AdditionalTags::TagList.new 'ruby', 'rails'

    assert_equal %w[ruby rails], tag_list
  end

  def test_add_single_tag
    tag_list = AdditionalTags::TagList.new
    tag_list.add 'ruby'

    assert_equal %w[ruby], tag_list
  end

  def test_add_multiple_tags
    tag_list = AdditionalTags::TagList.new
    tag_list.add 'ruby', 'rails'

    assert_equal %w[ruby rails], tag_list
  end

  def test_add_with_parse_option
    tag_list = AdditionalTags::TagList.new
    tag_list.add 'ruby, rails', parse: true

    assert_equal %w[ruby rails], tag_list
  end

  def test_add_prevents_duplicates
    tag_list = AdditionalTags::TagList.new 'ruby'
    tag_list.add 'ruby'

    assert_equal %w[ruby], tag_list
  end

  def test_add_preserves_case
    tag_list = AdditionalTags::TagList.new
    tag_list.add 'Ruby', 'ruby'

    assert_equal %w[Ruby ruby], tag_list
  end

  def test_shovel_operator
    tag_list = AdditionalTags::TagList.new
    tag_list << 'ruby'

    assert_includes tag_list, 'ruby'
  end

  def test_remove_single_tag
    tag_list = AdditionalTags::TagList.new 'ruby', 'rails'
    tag_list.remove 'ruby'

    assert_equal %w[rails], tag_list
  end

  def test_remove_with_parse_option
    tag_list = AdditionalTags::TagList.new 'ruby', 'python', 'rails'
    tag_list.remove 'ruby, python', parse: true

    assert_equal %w[rails], tag_list
  end

  def test_to_s_simple_list
    tag_list = AdditionalTags::TagList.new 'ruby', 'rails'

    assert_equal 'ruby, rails', tag_list.to_s
  end

  def test_to_s_quotes_tags_with_commas
    tag_list = AdditionalTags::TagList.new 'ruby, the language', 'python'

    assert_equal '"ruby, the language", python', tag_list.to_s
  end

  def test_plus_operator_returns_tag_list
    list_a = AdditionalTags::TagList.new 'ruby'
    list_b = AdditionalTags::TagList.new 'rails'
    result = list_a + list_b

    assert_kind_of AdditionalTags::TagList, result
    assert_equal %w[ruby rails], result
  end

  def test_plus_operator_removes_duplicates
    list_a = AdditionalTags::TagList.new 'ruby', 'rails'
    list_b = AdditionalTags::TagList.new 'rails', 'python'
    result = list_a + list_b

    assert_equal %w[ruby rails python], result
  end

  def test_concat_prevents_duplicates
    tag_list = AdditionalTags::TagList.new 'ruby'
    other = %w[ruby rails]
    tag_list.concat other

    assert_equal %w[ruby rails], tag_list
  end

  def test_strips_whitespace_from_tags
    tag_list = AdditionalTags::TagList.new
    tag_list.add '  ruby  ', ' rails '

    assert_equal %w[ruby rails], tag_list
  end

  def test_rejects_empty_entries
    tag_list = AdditionalTags::TagList.new
    tag_list.add '', '  ', 'ruby'

    assert_equal %w[ruby], tag_list
  end
end
