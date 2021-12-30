# frozen_string_literal: true

module AdditionalTags
  module Patches
    module WikiPagePatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        acts_as_ordered_taggable

        alias_method :safe_attributes_without_tags=, :safe_attributes=
        alias_method :safe_attributes=, :safe_attributes_with_tags=

        before_save :sort_tag_list
      end

      class_methods do
        def project_joins
          ["JOIN wikis ON wikis.id = #{table_name}.wiki_id",
           "JOIN #{Project.table_name} ON wikis.project_id = #{Project.table_name}.id"]
        end

        def available_tags(**options)
          options[:project_join] = project_joins
          options[:permission] = :view_wiki_pages
          AdditionalTags::Tags.available_tags self, **options
        end

        def with_tags_scope(project: nil, wiki: nil)
          scope = if wiki
                    wiki.pages
                  else
                    scope = WikiPage.joins wiki: :project
                    scope = scope.where wikis: { project_id: project.id } if project
                    scope
                  end

          scope = scope.visible User.current, project: project if scope.respond_to? :visible
          scope
        end

        def with_tags(tag, project: nil, order: 'title_asc', max_entries: nil)
          wiki = project&.wiki

          scope = with_tags_scope wiki: wiki, project: project
          scope = scope.limit max_entries if max_entries

          tags = Array tag
          tags.map!(&:strip)
          tags.reject!(&:blank?)
          return [] if tags.count.zero?

          tags.map!(&:downcase)

          scope = scope.where(id: tagged_with(tags, any: true).ids)
                       .with_updated_on

          return scope if order.nil?

          sorted = order.split '_'
          raise 'unsupported sort order' if sorted != 2 && %w[title date].exclude?(sorted.first)

          order_dir = sorted.second == 'desc' ? 'DESC' : 'ASC'

          case sorted.first
          when 'date'
            scope.joins(:content)
                 .reorder("#{WikiContent.table_name}.updated_on #{order_dir}")
          else
            if wiki.nil?
              scope.order "#{Project.table_name}.name, #{WikiPage.table_name}.title #{order_dir}"
            else
              scope.includes(:parent).order "#{WikiPage.table_name}.title #{order_dir}"
            end
          end
        end
      end

      module InstanceMethods
        def safe_attributes_with_tags=(attrs, user = User.current)
          if !attrs.is_a?(Array) && attrs && attrs[:tag_list]
            tags = attrs[:tag_list]
            tags = Array(tags).reject(&:empty?)

            # only assign it, if changed
            if tags == tag_list ||
               !AdditionalTags.setting?(:active_wiki_tags) ||
               !user.allowed_to?(:add_wiki_tags, project)
              attrs.delete :tag_list
            else
              attrs[:tag_list] = tags
              self.tag_list = tags
            end
          end

          send :safe_attributes_without_tags=, attrs, user
        end

        private

        def sort_tag_list
          return unless tag_list.present? && tag_list_changed?

          self.tag_list = AdditionalTags::Tags.sort_tags tag_list
        end
      end
    end
  end
end
