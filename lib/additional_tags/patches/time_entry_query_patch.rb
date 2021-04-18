# frozen_string_literal: true

require_dependency 'time_entry_query'

module AdditionalTags
  module Patches
    module TimeEntryQueryPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        alias_method :initialize_available_filters_without_tags, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_tags

        alias_method :available_columns_without_tags, :available_columns
        alias_method :available_columns, :available_columns_with_tags
      end

      module InstanceMethods
        def initialize_available_filters_with_tags
          initialize_available_filters_without_tags
          initialize_issue_tags_filter
        end

        def available_columns_with_tags
          if @available_columns.nil?
            @available_columns = available_columns_without_tags
            if AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, project, global: true)
              @available_columns << QueryColumn.new(:issue_tags)
            end
          else
            available_columns_without_tags
          end
          @available_columns
        end

        def sql_for_issue_tags_field(_field, operator, values)
          build_sql_for_tags_field klass: Issue, operator: operator, values: values
        end
      end
    end
  end
end
