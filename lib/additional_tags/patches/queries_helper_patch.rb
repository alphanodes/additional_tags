# frozen_string_literal: true

module AdditionalTags
  module Patches
    module QueriesHelperPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def column_content(column, item)
          if (column.name == :issue_tags || item.is_a?(Issue) && column.name == :tags) &&
             respond_to?(:additional_tag_links)
            tags = if item.instance_variable_defined? :@visible_tags
                     item.instance_variable_get :@visible_tags
                   elsif Setting.display_subprojects_issues?
                     # permission check required (expensive)
                     return unless User.current.allowed_to? :view_issue_tags, item.project

                     column.value item
                   else
                     # no permission check required
                     column.value item
                   end

            additional_tag_links tags, tag_controller: 'issues'
          else
            super
          end
        end
      end
    end
  end
end
