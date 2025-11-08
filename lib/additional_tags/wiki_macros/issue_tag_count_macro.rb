# frozen_string_literal: true

module AdditionalTags
  # Issue tag count macros
  module WikiMacros
    module IssueTagCountMacro
      Redmine::WikiFormatting::Macros.register do
        desc <<-DESCRIPTION
    Show the number of issues for a tag.

    Syntax:

      {{issue_tag_count(TAG, all_projects=BOOL)}}

    Examples:

      {{issue_tag_count(Bug)}}
      ...Show the number of issues for the tag 'Bug' of the current project

      {{issue_tag_count(Bug, all_projects=true)}}
      ...Show the number of issues for the tag 'Bug' of all projects
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
