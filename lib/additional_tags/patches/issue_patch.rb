# frozen_string_literal: true

module AdditionalTags
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        include Additionals::EntityMethodsGlobal
        include InstanceMethods
        acts_as_ordered_taggable

        before_save :prepare_save_tag_change
        before_save :sort_tag_list

        after_commit :add_remove_unused_tags_job, on: %i[update destroy],
                                                  if: proc { AdditionalTags.setting?(:active_issue_tags) }

        alias_method :safe_attributes_without_tags=, :safe_attributes=
        alias_method :safe_attributes=, :safe_attributes_with_tags=

        alias_method :copy_from_without_tags, :copy_from
        alias_method :copy_from, :copy_from_with_tags
      end

      class_methods do
        def allowed_tags?(tags)
          allowed_tags = available_tags.map(&:name)
          tags.all? { |tag| allowed_tags.include? tag }
        end

        def group_by_status_with_tags(project = nil)
          visible(User.current, project: project).joins(:status)
                                                 .joins(:tags)
                                                 .group(:is_closed, 'tag_id')
                                                 .count
        end

        def available_tags(**options)
          options[:permission] = :view_issues
          tags = AdditionalTags::Tags.available_tags self, **options
          return tags unless options[:open_issues_only]

          tags.joins("JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{table_name}.status_id")
              .where(issue_statuses: { is_closed: false })
        end
      end

      module InstanceMethods
        # tag_list_changed? is broken for after_save
        # tag_list_changed? is not working here, too!
        def prepare_save_tag_change
          return unless defined?(tag_list) && defined?(tag_list_was) && !tag_list_was.nil?

          @prepare_save_tag_change ||= tag_list != tag_list_was
        end

        def safe_attributes_with_tags=(attrs, user = User.current)
          if attrs && attrs[:tag_list]
            tags = attrs.delete :tag_list
            tags = Array(tags).reject(&:empty?)

            if user.allowed_to?(:create_issue_tags, project) ||
               user.allowed_to?(:edit_issue_tags, project) && Issue.allowed_tags?(tags)
              attrs[:tag_list] = tags
              self.tag_list = tags
            end
          end

          send :safe_attributes_without_tags=, attrs, user
        end

        # copy_from requires hash for Redmine - works with Ruby 3
        # rubocop: disable Style/OptionHash
        def copy_from_with_tags(arg, options = {})
          copy_from_without_tags arg, options
          issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          self.tag_list = issue.tag_list
          self
        end
        # rubocop: enable Style/OptionHash

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
