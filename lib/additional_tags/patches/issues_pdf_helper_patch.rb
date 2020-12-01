module AdditionalTags
  module Patches
    module IssuesPdfHelperPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        alias_method :fetch_row_values_without_additional_tags, :fetch_row_values
        alias_method :fetch_row_values, :fetch_row_values_with_additional_tags
      end

      module InstanceMethods
        def fetch_row_values_with_additional_tags(issue, query, level)
          query.inline_columns.collect do |column|
            s = if column.is_a? QueryCustomFieldColumn
                  cv = issue.visible_custom_field_values.detect { |v| v.custom_field_id == column.custom_field.id }
                  show_value(cv, false)
                else
                  value = issue.send(column.name)
                  value = '  ' * level + value if column.name == :subject

                  if value.is_a? Date
                    format_date(value)
                  elsif value.is_a? Time
                    format_time(value)
                  elsif value.respond_to? :map
                    # If a value is mappable then we need each of it's elements
                    # string representation
                    value.map!(&:to_s)
                    value.compact!
                    value.join ','
                  else
                    value
                  end
                end
            s.to_s
          end
        end
      end
    end
  end
end
