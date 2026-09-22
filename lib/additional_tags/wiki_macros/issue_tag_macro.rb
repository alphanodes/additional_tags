# frozen_string_literal: true

module AdditionalTags
  # Issue tag macros
  module WikiMacros
    module IssueTagMacro
      Redmine::WikiFormatting::Macros.register do
        desc <<-DESCRIPTION
    Display a list of issues with a tag.

    Only issues visible to the current user are listed. By default only issues
    of the current project are listed (without subprojects). Without a current
    project (e.g. in a global issue list) N/A is shown, unless all_projects=true
    is set. Tag names are not case sensitive. If no issue matches,
    "No data to display" is shown.

    Syntax:

      {{issue_tag(TAG [, title=STRING, with_count=BOOL, all_projects=BOOL])}}

      title: heading above the list (default: none)
      with_count: add the number of issues to the title, only used with title (default: false)
      all_projects: list issues of all projects (default: false)

    Examples:

      {{issue_tag(Bug)}}
      ...Show a list of issues with the tag 'Bug' in the current project

      {{issue_tag(Bug, title=Bug issues)}}
      ...Show the list with the heading 'Bug issues'

      {{issue_tag(Bug, title=Bug issues, with_count=true)}}
      ...Show the list with the heading 'Bug issues' followed by the number of issues

      {{issue_tag(Bug, all_projects=true)}}
      ...Show a list of issues with the tag 'Bug' in all projects
        DESCRIPTION

        macro :issue_tag do |_obj, args|
          args, options = extract_macro_options args, :title, :with_count, :all_projects
          raise l(:errors_no_or_invalid_arguments) if args.empty?

          tag_name = args.first
          issues = Issue.visible

          if RedminePluginKit.false? options[:all_projects]
            # no project available if used in description or last_notes in global list
            return 'N/A' unless @project

            issues = issues.where project_id: @project&.id
          end

          issues = issues.tagged_with tag_name

          s = []
          if options[:title].present?
            title = options[:title]
            title << " (#{issues.count})" if RedminePluginKit.true? options[:with_count]
            s << tag.h3(title)
          end

          s << if issues.any?
                 tag.ul class: "wiki-flat issue_tag issue_tag_#{tag_name}" do
                   issues.map { |issue| concat(tag.li(link_to_issue_with_subject(issue))) }
                 end
               else
                 tag.div l(:label_no_data), class: 'no_entries'
               end
          safe_join s
        end
      end
    end
  end
end
