# frozen_string_literal: true

module DashboardBlocks
  class IssueTagsBlock < Base
    block_id 'issue_tags'
    label :field_issue_tags
    permission :view_issue_tags
    async partial: 'dashboards/blocks/issue_tags'
    setting :with_table_of_values, type: :boolean, label: :label_with_table_of_values
    setting :open_issues_only, type: :boolean, label: :label_open_issues_only
    setting :use_colors, type: :boolean, label: :label_use_colors

    def available?
      AdditionalTags.setting? :active_issue_tags
    end
  end
end
