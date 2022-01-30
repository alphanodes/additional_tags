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
          @tags = Issue.available_tags name_like: build_search_query_term(params),
                                       sort_by: suggestion_order,
                                       order: (suggestion_order == 'name' ? 'ASC' : 'DESC')

          @tags = AdditionalTags::Tags.sort_tag_list @tags if suggestion_order == 'name'

          render layout: false, partial: 'additional_tag_list', locals: { unsorted: true }
        end

        def wiki_tags
          @tags = WikiPage.available_tags project: nil,
                                          name_like: build_search_query_term(params)
          render layout: false, partial: 'additional_tag_list', locals: { unsorted: true }
        end

        def all_tags
          return render_403 unless User.current.admin?

          q = build_search_query_term params
          sql_for_where = "LOWER(#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name) LIKE ?"
          @tags = ActsAsTaggableOn::Tag.where(sql_for_where, "%#{q.downcase}%")
                                       .order(name: :asc)

          render layout: false, partial: 'additional_tag_list', locals: { unsorted: true }
        end
      end
    end
  end
end
