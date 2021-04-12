# frozen_string_literal: true

module AdditionalTags
  module Patches
    module ReportsControllerPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def issue_report
          @tags = AdditionalTags::Tags.sort_tag_list Issue.available_tags(project_id: @project.id)
          @issues_by_tags = Issue.by_tags @project, with_subprojects: Setting.display_subprojects_issues?
          super
        end

        def issue_report_details
          if params[:detail] == 'tag' &&
             AdditionalTags.setting?(:active_issue_tags) &&
             User.current.allowed_to?(:view_issue_tags, @project)
            @field = 'tag_id'
            @rows = AdditionalTags::Tags.sort_tag_list Issue.available_tags(project_id: @project.id)
            @data = Issue.by_tags @project, with_subprojects: Setting.display_subprojects_issues?
            @report_title = l :field_tags
          else
            super
          end
        end
      end
    end
  end
end
