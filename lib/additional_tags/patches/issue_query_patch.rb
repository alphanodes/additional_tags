# frozen_string_literal: true

module AdditionalTags
  module Patches
    module IssueQueryPatch
      extend ActiveSupport::Concern

      included do
        include Additionals::Concerns::Query
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def issues(options = nil)
          options ||= {}
          issues = super(**options)
          return issues unless has_column? :tags

          Issue.load_visible_tags issues
          issues
        end

        def initialize_available_filters
          super

          initialize_tags_filter if !available_filters.key?('tags') &&
                                    AdditionalTags.setting?(:active_issue_tags) &&
                                    User.current.allowed_to?(:view_issue_tags, project, global: true)
        end

        def available_columns
          if @available_columns.nil?
            @available_columns = super

            if AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, project, global: true)
              @available_columns << ::QueryTagsColumn.new
            end
          else
            super
          end
          @available_columns
        end

        def build_from_params(params, defaults = {})
          super

          return self if params[:tag_id].blank?

          add_filter 'tags',
                     '=',
                     [AdditionalTag.find_by(id: params[:tag_id]).try(:name)]

          self
        end

        def sql_for_tags_field(field, _operator, values)
          build_sql_for_tags_field_with_permission klass: queried_class,
                                                   operator: operator_for(field),
                                                   values:,
                                                   permission: :view_issue_tags
        end

        # Backward compatibility for saved queries migrated from redmineup_tags plugin.
        # That plugin used 'issue_tags' as filter name, while additional_tags uses 'tags'.
        # Without this method, saved queries with 'issue_tags' filter cause 500 errors
        # because ActiveRecord tries to access non-existent column 'issues.issue_tags'.
        def sql_for_issue_tags_field(_field, operator, values)
          sql_for_tags_field 'tags', operator, values
        end
      end
    end
  end
end
