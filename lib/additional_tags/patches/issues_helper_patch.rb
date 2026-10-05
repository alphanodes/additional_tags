# frozen_string_literal: true

module AdditionalTags
  module Patches
    module IssuesHelperPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      # The subtask and related issue tables render their tags column through
      # column_content. Without the preloaded visible tags, it checks the
      # permission and queries the tags for every row.
      module InstanceOverwriteMethods
        # The subtask table renders its rows through issue_list
        def issue_list(issues, &)
          preload_related_issues_tags issues
          super
        end

        def render_issue_relations(issue, relations)
          preload_related_issues_tags(relations.map { |relation| relation.other_issue issue })
          super
        end

        private

        def preload_related_issues_tags(issues)
          return unless AdditionalTags.setting?(:active_issue_tags) && Setting.related_issues_default_columns.include?('tags')

          Issue.load_visible_tags issues
        end
      end
    end
  end
end
