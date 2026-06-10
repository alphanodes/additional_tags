# frozen_string_literal: true

module AdditionalTags
  module Concerns
    # Adds CSV/import tag_list support to any Import subclass.
    #
    # Behavior added to the host class:
    # - Adds 'tag_list' => 'field_tags' to AUTO_MAPPABLE_FIELDS so a CSV header
    #   named "tag_list" (or the localized "Tags" label) gets auto-selected in
    #   the mapping form.
    # - Wraps build_object so the tag_list value from the CSV row is passed
    #   through safe_attributes= on the resulting object.
    #
    # The host class is expected to define its own AUTO_MAPPABLE_FIELDS constant.
    module ImportWithTags
      extend ActiveSupport::Concern

      included do
        self::AUTO_MAPPABLE_FIELDS['tag_list'] = 'field_tags'

        prepend BuildObjectWithTags
      end

      module BuildObjectWithTags
        private

        def build_object(row, item)
          object = super
          return object if object.nil?

          tag_value = row_value row, 'tag_list'
          return object if tag_value.blank?

          object.send :safe_attributes=, { tag_list: tag_value }.with_indifferent_access, user
          object
        end
      end
    end
  end
end
