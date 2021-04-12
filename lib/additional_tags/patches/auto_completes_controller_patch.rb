# frozen_string_literal: true

module AdditionalTags
  module Patches
    module AutoCompletesControllerPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
      end

      module InstanceMethods
        def issue_tags
          suggestion_order = AdditionalTags.setting(:tags_suggestion_order) || 'name'
          @name = (params[:q] || params[:term]).to_s.strip
          @tags = Issue.available_tags name_like: @name,
                                       sort_by: suggestion_order,
                                       order: (suggestion_order == 'name' ? 'ASC' : 'DESC')

          @tags = AdditionalTags::Tags.sort_tag_list @tags if suggestion_order == 'name'

          render layout: false, partial: 'additional_tag_list', locals: { unsorted: true }
        end

        def wiki_tags
          @name = params[:q].to_s
          @tags = WikiPage.available_tags project: nil, name_like: @name
          render layout: false, partial: 'additional_tag_list', locals: { unsorted: true }
        end

        def all_tags
          return render_403 unless User.current.admin?

          @name = params[:q].to_s
          sql_for_where = "LOWER(#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name) LIKE ?"
          @tags = ActsAsTaggableOn::Tag.where(sql_for_where, "%#{@name.downcase}%")
                                       .order(name: :asc)

          render layout: false, partial: 'additional_tag_list', locals: { unsorted: true }
        end
      end
    end
  end
end
