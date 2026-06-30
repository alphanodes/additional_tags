# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class AdditionalTagsTest < AdditionalTags::TestCase
  def setup
    @project = projects :projects_001
  end

  def test_use_color
    with_plugin_settings 'additional_tags', tags_color_theme: '1' do
      assert AdditionalTags.use_colors?
    end
  end

  def test_use_color_with_theme
    with_plugin_settings 'additional_tags', tags_color_theme: 'a' do
      assert AdditionalTags.use_colors?
    end

    with_plugin_settings 'additional_tags', tags_color_theme: 'z' do
      assert AdditionalTags.use_colors?
    end
  end

  def test_use_color_as_default
    with_plugin_settings 'additional_tags', tags_color_theme: '' do
      assert AdditionalTags.use_colors?
    end

    with_plugin_settings 'additional_tags', tags_color_theme: nil do
      assert AdditionalTags.use_colors?
    end
  end

  def test_without_color
    with_plugin_settings 'additional_tags', tags_color_theme: '0' do
      assert_not AdditionalTags.use_colors?
    end
  end

  def test_fg_color_returns_black_on_light_background
    assert_equal 'black', AdditionalTags.fg_color('#ffffff')
    assert_equal 'black', AdditionalTags.fg_color('#ffff00')
  end

  def test_fg_color_returns_white_on_dark_background
    assert_equal 'white', AdditionalTags.fg_color('#000000')
    assert_equal 'white', AdditionalTags.fg_color('#cb2525')
  end
end
