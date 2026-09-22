# frozen_string_literal: true

module AdditionalTags
  # Issue tag count macros
  module WikiMacros
    module IssueTagCountMacro
      Redmine::WikiFormatting::Macros.register do
        desc <<-DESCRIPTION
    Show the number of issues with a tag.

    Only issues visible to the current user are counted. By default only issues
    of the current project are counted (without subprojects). Without a current
    project (e.g. in a global issue list) N/A is shown, unless all_projects=true
    is set. Tag names are not case sensitive.

    Syntax:

      {{issue_tag_count(TAG [, all_projects=BOOL])}}

      all_projects: count issues of all projects (default: false)

    Examples:

      {{issue_tag_count(Bug)}}
      ...Show the number of issues with the tag 'Bug' in the current project

      {{issue_tag_count(Bug, all_projects=true)}}
      ...Show the number of issues with the tag 'Bug' in all projects
        DESCRIPTION

        macro :issue_tag_count do |_obj, args|
          args, options = extract_macro_options args, :all_projects
          raise l(:errors_no_or_invalid_arguments) if args.empty?

          tag = args.first
          issues = Issue.visible

          if RedminePluginKit.false? options[:all_projects]
            # no project available if used in description or last_notes in global list
            return 'N/A' unless @project

            issues = issues.where project_id: @project
          end

          issues = issues.tagged_with tag
          issues.count
        end
      end
    end
  end
end
