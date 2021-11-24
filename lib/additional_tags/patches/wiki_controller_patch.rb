# frozen_string_literal: true

module AdditionalTags
  module Patches
    module WikiControllerPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
        helper :additional_tags
        helper :additional_tags_wiki

        include AdditionalTagsWikiHelper

        before_action :find_page_for_update_tags, only: :update_tags
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

          @pages = WikiPage.with_tags @tag, project: @project

          respond_to do |format|
            format.html do
              render template: 'wiki/tag_index'
            end
            format.api
          end
        end

        private

        # find_existing_page can not be used from wiki_controller, because it would be disable index only rule
        def find_page_for_update_tags
          @page = @wiki.find_page params[:id]
          render_404 if @page.nil?
        end
      end
    end
  end
end
