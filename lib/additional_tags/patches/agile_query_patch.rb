# frozen_string_literal: true

module AdditionalTags
  module Patches
    module AgileQueryPatch
      extend ActiveSupport::Concern

      included do
        include Additionals::Concerns::Query
        prepend InstanceOverwriteMethods
        include InstanceMethods

        add_available_column ::QueryTagsColumn.new
      end

      module InstanceOverwriteMethods
        def initialize_available_filters
          super

          initialize_tags_filter if !available_filters.key?('tags') &&
                                    User.current.allowed_to?(:view_issue_tags, project, global: true)
        end
      end

      module InstanceMethods
        def sql_for_tags_field(_field, operator, value)
          issues = case operator
                   when '=', '!'
                     Issue.tagged_with value.clone, any: true
                   when '!*'
                     Issue.joins(:tags).uniq
                   else
                     Issue.tagged_with(AdditionalTag.all.map(&:to_s), any: true)
                   end

          compare   = operator.include?('!') ? 'NOT IN' : 'IN'
          ids_list  = issues.collect(&:id).push(0).join(',')
          "( #{Issue.table_name}.id #{compare} (#{ids_list}) ) "
        end
      end
    end
  end
end
