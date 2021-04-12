# frozen_string_literal: true

module AdditionalTagsWikiHelper
  def sidebar_tags
    unless @sidebar_tags
      @sidebar_tags = []
      @sidebar_tags = WikiPage.available_tags project: @project if AdditionalTags.show_sidebar_tags?
    end
    @sidebar_tags
  end

  def render_sidebar_tags
    options = { show_count: AdditionalTags.setting?(:show_with_count),
                style: AdditionalTags.setting(:tags_sidebar).to_sym,
                link_wiki_tag: true,
                project: @project }

    render_tags_list sidebar_tags, options
  end

  def render_wiki_index_title(project, tag = nil)
    if tag.present?
      if project.nil?
        title = [link_to(l(:label_wiki), wiki_index_path)]
        title << Additionals::LIST_SEPARATOR
        title << t(:label_wiki_index_for_tag_html, tag: tag)
        safe_join title, ' '
      else
        t :label_wiki_index_for_tag_html, tag: tag
      end
    else
      l :label_wiki
    end
  end

  def wiki_pages_with_tag(tag, project = nil)
    wiki = project&.wiki

    scope = if wiki
              wiki.pages
            else
              WikiPage.joins wiki: :project
            end

    scope = scope.visible User.current, project: project if scope.respond_to? :visible

    scope = scope.joins(AdditionalTags::Tags.tag_to_joins(WikiPage))
                 .where("LOWER(#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name) = LOWER(:p)",
                        p: tag.to_s.strip)
                 .with_updated_on
                 .joins(wiki: :project)

    if wiki.nil?
      scope.order "#{Project.table_name}.name, #{WikiPage.table_name}.title"
    else
      scope.includes(:parent).order "#{WikiPage.table_name}.title"
    end
  end
end
