# frozen_string_literal: true

module AdditionalTags
  class TagListType < ActiveModel::Type::Value
    def cast(value)
      case value
      when TagList then value
      when Array then TagList.new(*value)
      when String then TagList.new(*DefaultParser.parse(value))
      end
    end

    def changed_in_place?(raw_old_value, new_value)
      raw_old_value != new_value&.to_s
    end
  end
end
