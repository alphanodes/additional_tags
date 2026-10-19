# frozen_string_literal: true

module DashboardBlocks
  class IssueTagsBlock < TagsBlock
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

    def totals_params
      { set_filter: 1, tags: '*', status_id: open_issues_only ? 'o' : '*' }
    end

    def entities_label
      I18n.t :label_issue_plural
    end

    private

    def available_tags
      Issue.available_tags project:, open_issues_only:, user:
    end

    def count_scope
      Issue.group_by_status_with_tags project, user
    end

    def tag_controller
      'issues'
    end

    def query_class
      IssueQuery
    end

    def count_method
      :issue_count
    end

    # Closed is true
    def statuses
      { false => :open, true => :closed }
    end

    # The list filters open and closed issues by operator
    def tag_filter(status_id)
      status_id = only_status if status_id.nil?
      { field: :status_id, operator: status_id ? 'c' : 'o' } unless status_id.nil?
    end

    def status_label(_status_id, key)
      I18n.t :"label_#{key}_issues_plural"
    end

    def group_options
      { group_id_is_bool: true }
    end

    def only_status
      false if open_issues_only
    end
  end
end
