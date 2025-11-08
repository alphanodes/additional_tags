# frozen_string_literal: true

module AdditionalTags
  # Issue tag macros
  module WikiMacros
    module IssueTagMacro
      Redmine::WikiFormatting::Macros.register do
        desc <<-DESCRIPTION
    Display issue list for a tag.

    Syntax:

      {{issue_tag(TAG, title=STRING, with_count=BOOL, all_projects=BOOL)}}

    Examples:

      {{issue_tag(Bug)}}
      ...Show a list of issues with the tag 'Bug' of the current project
      {{issue_tag(Bug,title=Bug issues)}}
      ...Show a list of issues with the tag 'Bug' and set a title for the list
      {{issue_tag(Bug,title=Bug issues, with_count=true)}}
      ...Show a list of issues with the tag 'Bug' and set a title for the list
      and add the amount of entries after title
      {{issue_tag(Bug, all_projects=true)}}
      ...Show a list of issues with the tag 'Bug' of all projects
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
                   issues.map { |issue| concat(tag.li(link_to("##{issue.id} #{issue.subject}", issue_path(issue)))) }
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
