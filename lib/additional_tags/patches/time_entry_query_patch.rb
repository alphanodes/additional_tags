# frozen_string_literal: true

require_dependency 'time_entry_query'

module AdditionalTags
  module Patches
    module TimeEntryQueryPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
        include InstanceMethods
      end

      module InstanceOverwriteMethods
        def initialize_available_filters
          super
          initialize_issue_tags_filter
        end

        def available_columns
          if @available_columns.nil?
            @available_columns = super
            if AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, project, global: true)
              @available_columns << QueryColumn.new(:issue_tags)
            end
          else
            super
          end
          @available_columns
        end
      end

      module InstanceMethods
        def sql_for_issue_tags_field(_field, operator, values)
          build_sql_for_tags_field klass: Issue, operator:, values:
        end
      end
    end
  end
end
