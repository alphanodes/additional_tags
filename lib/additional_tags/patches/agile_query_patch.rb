module AdditionalTags
  module Patches
    module AgileQueryPatch
      extend ActiveSupport::Concern

      included do
        include AdditionalsQuery
        include InstanceMethods

        alias_method :initialize_available_filters_without_tags, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_tags

        add_available_column QueryColumn.new(:tags)
      end

      module InstanceMethods
        def sql_for_tags_field(_field, operator, value)
          case operator
          when '=', '!'
            issues = Issue.tagged_with(value.clone)
          when '!*'
            issues = Issue.joins(:tags).uniq
          else
            issues = Issue.tagged_with(ActsAsTaggableOn::Tag.all.map(&:to_s), any: true)
          end

          compare   = operator.include?('!') ? 'NOT IN' : 'IN'
          ids_list  = issues.collect(&:id).push(0).join(',')
          "( #{Issue.table_name}.id #{compare} (#{ids_list}) ) "
        end

        def initialize_available_filters_with_tags
          initialize_available_filters_without_tags

          initialize_tags_filter if !available_filters.key?('tags') &&
                                    User.current.allowed_to?(:view_issue_tags, project, global: true)
        end
      end
    end
  end
end
