# frozen_string_literal: true

module AdditionalTags
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        include Additionals::EntityMethodsGlobal
        include InstanceMethods
        acts_as_ordered_taggable

        before_save :prepare_save_tag_change, if: proc { AdditionalTags.setting?(:active_issue_tags) }
        before_save :sort_tag_list, if: proc { AdditionalTags.setting?(:active_issue_tags) }

        validate :validate_tags, if: proc { AdditionalTags.setting?(:active_issue_tags) }

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

        def group_by_status_with_tags(project = nil, user = User.current)
          scope = if project && Setting.display_subprojects_issues?
                    visible(user).where(AdditionalTags::Tags.subproject_sql(project))
                  else
                    visible user, project: project
                  end

          scope.joins(:status)
               .joins(:tags)
               .group(:is_closed, 'tag_id')
               .count
        end

        def available_tags(**options)
          options[:permission] ||= :view_issue_tags
          tags = AdditionalTags::Tags.available_tags self, **options
          return tags unless options[:open_issues_only]

          tags.joins("JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{table_name}.status_id")
              .where(issue_statuses: { is_closed: false })
        end

        def common_tag_list_from_issues(ids)
          common_tags = ActsAsTaggableOn::Tag.joins(:taggings)
                                             .select(
                                               "#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id",
                                               "#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name"
                                             )
                                             .where(taggings: { taggable_type: 'Issue', taggable_id: ids })
                                             .group(
                                               "#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id",
                                               "#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name"
                                             )
                                             .having('count(*) = ?', ids.count).to_a

          ActsAsTaggableOn::TagList.new common_tags
        end

        def load_visible_tags(issues, user = User.current)
          return if issues.blank?

          available_projects = Project.where(AdditionalTags::Tags.visible_condition(user)).ids

          issues.each do |issue|
            tags = if available_projects.include? issue.project_id
                     issue.tags
                   else
                     []
                   end
            issue.instance_variable_set :@visible_tags, tags
          end
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
          send :safe_attributes_without_tags=, attrs, user # required to fire first to get loaded project
          return unless attrs && attrs[:tag_list]

          tags = attrs.delete :tag_list
          tags = Array(tags).reject(&:empty?)

          if user.allowed_to?(:create_issue_tags, project) ||
             user.allowed_to?(:edit_issue_tags, project) && Issue.allowed_tags?(tags)
            attrs[:tag_list] = tags # required fix for journal details
            self.tag_list = tags    # required fix for tags
          end
        end

        def copy_from_with_tags(arg, options = nil)
          options ||= {} # works with Ruby 3

          copy_from_without_tags arg, **options
          issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          self.tags = issue.tags           # required for bulk copy
          self.tag_list = tags.map(&:name) # required for copy
          self
        end

        private

        def sort_tag_list
          tags = tag_list.reject(&:empty?)
          return unless tags.present? && tag_list_changed?

          self.tag_list = AdditionalTags::Tags.sort_tags tags
        end

        def validate_tags
          return if !User.current.allowed_to?(:create_issue_tags, project) &&
                    !(User.current.allowed_to?(:edit_issue_tags, project) && Issue.allowed_tags?(tags))

          errors.add :tag_list, :invalid_mutually_exclusive_tags unless AdditionalTag.valid_mutually_exclusive_tag tag_list
        end
      end
    end
  end
end
