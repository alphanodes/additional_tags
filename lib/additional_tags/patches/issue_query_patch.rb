# frozen_string_literal: true

module AdditionalTags
  module Patches
    module IssueQueryPatch
      extend ActiveSupport::Concern

      included do
        include AdditionalsQuery
        prepend InstanceOverwriteMethods
        include InstanceMethods

        alias_method :initialize_available_filters_without_tags, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_tags

        alias_method :available_columns_without_tags, :available_columns
        alias_method :available_columns, :available_columns_with_tags
      end

      module InstanceOverwriteMethods
        def build_from_params(params, defaults = {})
          super

          return self if params[:tag_id].blank?

          add_filter 'tags',
                     '=',
                     [ActsAsTaggableOn::Tag.find_by(id: params[:tag_id]).try(:name)]

          self
        end
      end

      module InstanceMethods
        def initialize_available_filters_with_tags
          initialize_available_filters_without_tags

          initialize_tags_filter if !available_filters.key?('tags') &&
                                    AdditionalTags.setting?(:active_issue_tags) &&
                                    User.current.allowed_to?(:view_issue_tags, project, global: true)
        end

        def available_columns_with_tags
          if @available_columns.nil?
            @available_columns = available_columns_without_tags

            if AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, project, global: true)
              @available_columns << ::QueryTagsColumn.new
            end
          else
            available_columns_without_tags
          end
          @available_columns
        end
      end
    end
  end
end
