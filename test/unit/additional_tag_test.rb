# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class AdditionalTagTest < AdditionalTags::TestCase
  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :additional_tags, :additional_taggings

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
