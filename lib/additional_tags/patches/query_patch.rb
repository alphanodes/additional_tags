# frozen_string_literal: true

module AdditionalTags
  module Patches
    module QueryPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
      end

      module InstanceMethods
        def sql_for_tags_field(field, _operator, values)
          build_sql_for_tags_field klass: queried_class,
                                   operator: operator_for(field),
                                   values:
        end

        def initialize_tags_filter
          add_available_filter 'tags', type: :list_optional,
                                       values: -> { available_tag_values queried_class }
        end

        def initialize_issue_tags_filter
          return unless AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, project, global: true)

          add_available_filter 'issue.tags',
                               type: :list_optional,
                               name: l('label_attribute_of_issue', name: l(:field_tags)),
                               values: -> { available_tag_values Issue }
        end

        def available_tag_values(klass)
          klass.available_tags(project:)
               .pluck(:name)
               .map { |name| [name, name] }
        end

        def build_subquery_for_tags_field(klass:, operator:, values:, joined_table:, joined_field:,
                                          source_field: 'id', target_field: 'issue_id')
          quoted_joined_table = self.class.connection.quote_table_name joined_table
          quoted_joined_field = self.class.connection.quote_column_name joined_field
          quoted_source_field = self.class.connection.quote_column_name source_field
          quoted_target_field = self.class.connection.quote_column_name target_field
          subsql = AdditionalTagging.joins("INNER JOIN #{quoted_joined_table}" \
                                           " ON additional_taggings.taggable_id = #{quoted_joined_table}.#{quoted_target_field}")
                                    .where(taggable_type: klass.name)
                                    .where("#{self.class.connection.quote_table_name queried_table_name}.#{quoted_source_field} =" \
                                           " #{quoted_joined_table}.#{quoted_joined_field}")
                                    .select(1)

          subsql = subsql.where taggable_id: klass.tagged_with(values, any: true).select(:id) if %w[= !].include? operator

          if %w[= *].include? operator
            " EXISTS(#{subsql.to_sql})"
          else
            " NOT EXISTS(#{subsql.to_sql})"
          end
        end

        # NOTE: should be used, if tags required permission check
        def build_sql_for_tags_field_with_permission(klass:, operator:, values:, permission:)
          entries = if %w[= !].include? operator
                      klass.tagged_with values, any: true
                    else
                      allowed_projects = Project.where(Project.allowed_to_condition(User.current, permission))
                                                .select(:id)
                      klass.joins(:tags).where project_id: allowed_projects
                    end

          sql_for_tagged_ids klass, operator, entries.select(:id)
        end

        # NOTE: should be used, if tags do not require permission check
        def build_sql_for_tags_field(klass:, operator:, values:)
          entries = if %w[= !].include? operator
                      klass.tagged_with(values, any: true).select :id
                    else
                      AdditionalTagging.where(taggable_type: klass.name).select :taggable_id
                    end

          sql_for_tagged_ids klass, operator, entries
        end

        private

        # The ids stay in the database as a subquery: loading them first would
        # put every tagged entry into the SQL string. An empty subquery matches
        # nothing, so a filter on a deleted tag needs no special case.
        def sql_for_tagged_ids(klass, operator, id_scope)
          column = "#{klass.quoted_table_name}.#{klass.quoted_primary_key}"
          return "(#{column} IN (#{id_scope.to_sql}))" if %w[= *].include? operator

          # The tagged table can hang off the queried one from outside - a time entry without
          # an issue - and NULL NOT IN (...) is NULL, not true. Such a row would answer "has
          # no tags" with no while answering "is not <tag>" with yes. Core writes its own
          # negations the same way, see Query#sql_for_field.
          "(#{column} NOT IN (#{id_scope.to_sql}) OR #{column} IS NULL)"
        end
      end
    end
  end
end
