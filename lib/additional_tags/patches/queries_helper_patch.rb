# frozen_string_literal: true

module AdditionalTags
  module Patches
    module QueriesHelperPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        alias_method :column_content_without_tags, :column_content
        alias_method :column_content, :column_content_with_tags
      end

      module InstanceMethods
        def column_content_with_tags(column, item)
          if column.name == :issue_tags || item.is_a?(Issue) && column.name == :tags
            additional_tag_links column.value(item),
                                 tag_controller: 'issues',
                                 use_colors: AdditionalTags.setting?(:use_colors)
          else
            column_content_without_tags column, item
          end
        end
      end
    end
  end
end
