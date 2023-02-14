# frozen_string_literal: true

module AdditionalTagsIssuesHelper
  # Hacked render_api_custom_values to add plugin values to issue api
  def render_api_custom_values(custom_values, api)
    rc = super

    if @issue.present? &&
       (defined?(controller_name) && controller_name == 'issues' && action_name == 'show' || !defined?(controller_name)) &&
       AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, @project)

      api.array :tags do
        # support tags, which are not saved to database
        if @issue.tag_list.present?
          if @issue.tags.present? && @issue.tags.map(&:name) == @issue.tag_list
            @issue.tags.each do |tag|
              api.tag id: tag.id, name: tag.name
            end
          else
            @issue.tag_list.each do |tag_name|
              # there is no id for unsaved tags
              api.tag name: tag_name
            end
          end
        end
      end
    end

    if @time_entry.present? &&
       (defined?(controller_name) && controller_name == 'timelog' && action_name == 'show' || !defined?(controller_name)) &&
       AdditionalTags.setting?(:active_issue_tags) && User.current.allowed_to?(:view_issue_tags, @project)
      api.array :issue_tags do
        @time_entry.issue_tags.each do |tag|
          api.tag id: tag.id, name: tag.name
        end
      end
    end

    rc
  end

  def sidebar_tags
    # we do not want tags on issue import
    return if controller_name == 'imports'

    unless @sidebar_tags
      @sidebar_tags = []
      if AdditionalTags.show_sidebar_tags?
        @sidebar_tags = Issue.available_tags project: @project,
                                             open_issues_only: AdditionalTags.setting?(:open_issues_only)
      end
    end
    @sidebar_tags.to_a
  end

  def render_sidebar_tags
    options = { filter: AdditionalTags.setting?(:open_issues_only) ? { field: :status_id, operator: 'o' } : nil,
                project: @project }

    options[:tag_action] = 'show' if %w[gantts calendars].include? controller_name
    render_tags_list sidebar_tags, **options
  end
end
