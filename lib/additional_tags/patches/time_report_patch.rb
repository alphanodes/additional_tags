# frozen_string_literal: true

require_dependency 'query'

module AdditionalTags
  module Patches
    module TimeReportPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
        include InstanceMethods
      end

      module InstanceOverwriteMethods
        private

        def load_available_criteria
          return @load_available_criteria_with_tags if @load_available_criteria_with_tags

          @load_available_criteria_with_tags = super
          @load_available_criteria_with_tags['tags'] = { sql: "#{AdditionalTag.table_name}.id",
                                                         klass: AdditionalTag,
                                                         joins: additional_tags_join,
                                                         label: :field_tags }
          @load_available_criteria_with_tags
        end
      end

      module InstanceMethods
        private

        def additional_tags_join
          time_entry_table = Arel::Table.new TimeEntry.table_name
          issues_table = Arel::Table.new Issue.table_name, as: :issues_time_entries
          taggings_table = Arel::Table.new AdditionalTagging.table_name
          tags_table = Arel::Table.new AdditionalTag.table_name

          time_entry_table.join(issues_table)
                          .on(issues_table[:id].eq(time_entry_table[:issue_id]))
                          .join(taggings_table)
                          .on(taggings_table[:taggable_id].eq(issues_table[:id]).and(taggings_table[:taggable_type].eq('Issue')))
                          .join(tags_table)
                          .on(tags_table[:id].eq(taggings_table[:tag_id]))
                          .join_sources
        end
      end
    end
  end
end
