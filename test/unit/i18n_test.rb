# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class I18nTest < AdditionalTags::TestCase
  include Redmine::I18n

  def setup
    User.current = nil
  end

  def teardown
    set_language_if_valid 'en'
  end

  def test_valid_languages
    assert_kind_of Array, valid_languages
    assert_kind_of Symbol, valid_languages.first
  end

  def test_locales_validness
    lang_files_count = Dir[Rails.root.join('plugins/additional_tags/config/locales/*.yml')].size

    assert_equal 13, lang_files_count
    valid_languages.each do |lang|
      assert set_language_if_valid(lang)
      case lang.to_s
      when 'en'

        assert_equal 'Merge selected tags', l(:label_merge_selected_tags)
      when 'bg', 'cs', 'de', 'es', 'fa', 'fr', 'it', 'ja', 'ko', 'pl', 'pt-BR', 'ru'

        assert_not l(:label_merge_selected_tags) == 'Merge selected tags', lang
      end
    end

    set_language_if_valid 'en'
  end
end
