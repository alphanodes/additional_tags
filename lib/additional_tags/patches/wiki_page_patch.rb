module AdditionalTags
  module Patches
    module WikiPagePatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        acts_as_ordered_taggable

        safe_attributes 'tag_list', (->(page, _user) { user.allowed_to?(:add_wiki_tags, page.project) })

        alias_method :safe_attributes_without_tags=, :safe_attributes=
        alias_method :safe_attributes=, :safe_attributes_with_tags=

        before_save :sort_tag_list
      end

      class_methods do
        def project_joins
          ["JOIN wikis ON wikis.id = #{table_name}.wiki_id",
           "JOIN #{Project.table_name} ON wikis.project_id = #{Project.table_name}.id"]
        end

        def available_tags(options = {})
          options[:project_join] = project_joins
          options[:permission] = :view_wiki_pages
          AdditionalTags::Tags.available_tags self, options
        end
      end

      module InstanceMethods
        def safe_attributes_with_tags=(attrs, user = User.current)
          if !attrs.is_a?(Array) && attrs && attrs[:tag_list]
            tags = attrs[:tag_list]
            tags = Array(tags).reject(&:empty?)

            # only assign it, if changed
            if tags == tag_list
              attrs.delete :tag_list
            else
              attrs[:tag_list] = tags
              self.tag_list = tags
            end
          end

          send 'safe_attributes_without_tags=', attrs, user
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
