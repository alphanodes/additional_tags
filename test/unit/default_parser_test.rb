# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class DefaultParserTest < AdditionalTags::TestCase
  def test_parse_empty_string
    assert_equal [], AdditionalTags::DefaultParser.parse('')
  end

  def test_parse_nil
    assert_equal [], AdditionalTags::DefaultParser.parse(nil)
  end

  def test_parse_comma_separated_string
    assert_equal %w[ruby rails python], AdditionalTags::DefaultParser.parse('ruby, rails, python')
  end

  def test_parse_strips_whitespace
    assert_equal %w[ruby rails], AdditionalTags::DefaultParser.parse('  ruby , rails  ')
  end

  def test_parse_removes_empty_entries
    assert_equal %w[ruby rails], AdditionalTags::DefaultParser.parse('ruby,,rails,')
  end

  def test_parse_double_quoted_tags
    assert_equal ['ruby, the language', 'python'], AdditionalTags::DefaultParser.parse('"ruby, the language", python')
  end

  def test_parse_single_quoted_tags
    assert_equal ['ruby, the language', 'python'], AdditionalTags::DefaultParser.parse("'ruby, the language', python")
  end

  def test_parse_array_input
    assert_equal %w[ruby rails], AdditionalTags::DefaultParser.parse(%w[ruby rails])
  end

  def test_parse_utf8_characters
    assert_equal %w[Über Büro Gebäude], AdditionalTags::DefaultParser.parse('Über, Büro, Gebäude')
  end
end
