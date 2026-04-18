# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class UtilsTest < AdditionalTags::TestCase
  def test_using_postgresql_returns_boolean
    result = AdditionalTags::Utils.using_postgresql?

    assert_includes [true, false], result
  end

  def test_using_mysql_returns_boolean
    result = AdditionalTags::Utils.using_mysql?

    assert_includes [true, false], result
  end

  def test_using_postgresql_and_mysql_are_mutually_exclusive
    assert_not_equal AdditionalTags::Utils.using_postgresql?,
                     AdditionalTags::Utils.using_mysql?
  end

  def test_like_operator_returns_ilike_for_postgresql
    skip unless AdditionalTags::Utils.using_postgresql?

    assert_equal 'ILIKE', AdditionalTags::Utils.like_operator
  end

  def test_like_operator_returns_like_for_mysql
    skip unless AdditionalTags::Utils.using_mysql?

    assert_equal 'LIKE', AdditionalTags::Utils.like_operator
  end

  def test_like_operator_returns_string
    result = AdditionalTags::Utils.like_operator

    assert_kind_of String, result
    assert_includes %w[LIKE ILIKE], result
  end
end
