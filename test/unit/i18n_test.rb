# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class I18nTest < AdditionalTags::TestCase
  Additionals.define_i18n_tests self,
                                plugin: 'additional_tags',
                                control_string: :label_merge_selected_tags,
                                control_english: 'Merge selected tags'
end
