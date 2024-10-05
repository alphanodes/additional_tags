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
    assert_locales_validness plugin: 'additional_tags',
                             file_cnt: 13,
                             locales: %w[bg cs de es fa fr it ja ko pl pt-BR ru],
                             control_string: :label_merge_selected_tags,
                             control_english: 'Merge selected tags'
  end
end
