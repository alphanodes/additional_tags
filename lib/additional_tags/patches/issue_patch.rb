module AdditionalTags
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
        acts_as_ordered_taggable

        before_save :sort_tag_list

        alias_method :safe_attributes_without_tags=, :safe_attributes=
        alias_method :safe_attributes=, :safe_attributes_with_tags=

        alias_method :copy_from_without_tags, :copy_from
        alias_method :copy_from, :copy_from_with_tags
      end

      class_methods do
        def allowed_tags?(tags)
          allowed_tags = available_tags.map(&:name)
          tags.all? { |tag| allowed_tags.include?(tag) }
        end

        def by_tags(project, with_subprojects: false)
          count_and_group_by(project: project, association: :tags, with_subprojects: with_subprojects)
        end

        def available_tags(options = {})
          options[:permission] = :view_issues
          tags = AdditionalTags::Tags.available_tags self, options
          return tags unless options[:open_issues_only]

          tags.joins("JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{table_name}.status_id")
              .where(issue_statuses: { is_closed: false })
        end

        def remove_unused_tags!
          AdditionalTagsRemoveUnusedTagJob.perform_later
        end
      end

      module InstanceMethods
        def safe_attributes_with_tags=(attrs, user = User.current)
          self.safe_attributes_without_tags = attrs

          return unless attrs && attrs[:tag_list] && user.allowed_to?(:edit_issue_tags, project)

          tags = Array(attrs[:tag_list]).reject(&:empty?)
          return unless user.allowed_to?(:create_issue_tags, project) || Issue.allowed_tags?(tags)

          self.tag_list = tags
        end

        def copy_from_with_tags(arg, options = {})
          copy_from_without_tags(arg, options)
          issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          self.tag_list = issue.tag_list
          self
        end

        private

        def sort_tag_list
          tags = tag_list.reject(&:empty?)
          return unless tags.present? && tag_list_changed?

          self.tag_list = AdditionalTags::Tags.sort_tags tags
        end
      end
    end
  end
end
