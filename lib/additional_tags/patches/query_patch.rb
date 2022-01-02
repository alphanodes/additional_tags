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
          build_sql_for_tags_field klass: queried_class, operator: operator_for(field), values: values
        end

        def initialize_tags_filter(position: nil)
          add_available_filter 'tags', order: position,
                                       type: :list_optional,
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
          klass.available_tags(project: project)
               .pluck(:name)
               .map { |name| [name, name] }
        end

        def build_subquery_for_tags_field(klass:, operator:, values:, joined_table:, joined_field:,
                                          source_field: 'id', target_field: 'issue_id')
          quoted_joined_table = self.class.connection.quote_table_name joined_table
          quoted_joined_field = self.class.connection.quote_column_name joined_field
          quoted_source_field = self.class.connection.quote_column_name source_field
          quoted_target_field = self.class.connection.quote_column_name target_field
          subsql = ActsAsTaggableOn::Tagging.joins("INNER JOIN #{quoted_joined_table}" \
                                                   " ON additional_taggings.taggable_id = #{quoted_joined_table}.#{quoted_target_field}")
                                            .where(taggable_type: klass.name)
                                            .where("#{self.class.connection.quote_table_name queried_table_name}.#{quoted_source_field} ="\
                                                   " #{quoted_joined_table}.#{quoted_joined_field}")
                                            .select(1)

          if %w[= !].include? operator
            ids_list = klass.tagged_with(values, any: true).pluck :id
            subsql = subsql.where taggable_id: ids_list
          end

          if %w[= *].include? operator
            " EXISTS(#{subsql.to_sql})"
          else
            " NOT EXISTS(#{subsql.to_sql})"
          end
        end

        def build_sql_for_tags_field(klass:, operator:, values:)
          compare = ['=', '*'].include?(operator) ? 'IN' : 'NOT IN'
          case operator
          when '=', '!'
            ids_list = klass.tagged_with(values, any: true).pluck :id
            if ids_list.present?
              "(#{klass.table_name}.id #{compare} (#{ids_list.join ','}))"
            elsif values.present? && operator == '='
              # special case: filter with deleted tag
              '(1=0)'
            end
          else
            entries = ActsAsTaggableOn::Tagging.where taggable_type: klass.name
            id_table = klass.table_name
            "(#{id_table}.id #{compare} (#{entries.select(:taggable_id).to_sql}))"
          end
        end
      end
    end
  end
end
