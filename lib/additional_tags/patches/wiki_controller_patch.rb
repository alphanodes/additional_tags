module AdditionalTags
  module Patches
    module WikiControllerPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
        helper :additional_tags
        helper :additional_tags_wiki

        before_action :find_existing_page, only: :update_tags
      end

      module InstanceOverwriteMethods
        def update_tags
          @page.safe_attributes = [:tag_list]
          @page.tag_list = params[:wiki_page][:tag_list].to_a.reject(&:empty?)
          flash[:notice] = if @page.save
                             l :notice_successful_update
                           else
                             t :notice_failed_to_add_tags
                           end
          redirect_to project_wiki_page_path(@page.project, @page.title)
        end

        def index
          @tag = params[:tag]
          return super unless AdditionalTags.setting?(:active_wiki_tags) && @tag.present?

          load_pages_for_index_with_tag

          respond_to do |format|
            format.html do
              render template: 'wiki/tag_index'
            end
            format.api
          end
        end

        private

        def load_pages_for_index_with_tag
          pattern = "%#{@tag.to_s.strip}%"
          @pages = @wiki.pages
                        .joins(AdditionalTags::Tags.tag_to_joins(WikiPage))
                        .where("LOWER(#{ActiveRecord::Base.connection.quote_table_name(ActsAsTaggableOn.tags_table)}.name) LIKE LOWER(:p)",
                               p: pattern)
                        .with_updated_on
                        .distinct
                        .reorder("#{WikiPage.table_name}.title")
                        .includes(wiki: :project)
                        .includes(:parent).to_a
        end
      end
    end
  end
end
