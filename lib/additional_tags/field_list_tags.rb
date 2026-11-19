# frozen_string_literal: true

module AdditionalTags
  # The tags filter of a list macro (Additionals::FieldList): tags=TAG with the
  # operators and keywords of every other filter of the list. A list includes
  # it and hands filters named tags_filter? to filter_by_tags.
  module FieldListTags
    TAGS_FILTER = 'tags'

    private

    # The name of the filter is reserved, so a custom field of that name is
    # filtered by its id.
    def tags_filter?(filter)
      filter.name.casecmp? TAGS_FILTER
    end

    # A tag is a name, so it is compared as a whole and never looked into
    def filter_by_tags(scope, filter)
      if filter.contains?
        raise Additionals::FieldList::Error.new(:error_field_list_operator_not_supported,
                                                operator: filter.operator,
                                                name: filter.name)
      end

      taggings = AdditionalTagging.where taggable_type: scope.klass.base_class.name
      apply_filter scope, filter, taggings.select(:taggable_id) do |value|
        taggings.joins(:tag).where(like_value("#{AdditionalTag.table_name}.name", value, filter)).select(:taggable_id)
      end
    end
  end
end
