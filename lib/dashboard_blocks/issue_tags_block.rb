# frozen_string_literal: true

module DashboardBlocks
  class IssueTagsBlock < Base
    block_id 'issue_tags'
    label :field_issue_tags
    permission :view_issue_tags
    async partial: 'dashboards/blocks/issue_tags'

    def available?
      AdditionalTags.setting? :active_issue_tags
    end
  end
end
