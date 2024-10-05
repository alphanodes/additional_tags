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
    options = { link_wiki_tag: true,
                project: @project }

    render_tags_list sidebar_tags, **options
  end

  def render_wiki_index_title(title, project: nil, name: nil, tag: nil)
    title = l title unless is_a? Symbol

    if tag.present?
      tag_object = ActsAsTaggableOn::Tag.new name: tag

      if project
        safe_join [l(:label_wiki_index_for_tag), additional_tag_link(tag_object, link: '#')], ' '
      else
        items = [link_to(title, wiki_index_path)]
        items << safe_join([l(:label_wiki_index_for_tag), additional_tag_link(tag_object, link: '#')], ' ')
        render_breadcrumb items
      end
    elsif name.present?
      render_breadcrumb [link_to(title, wiki_index_path),
                         name]
    else
      title
    end
  end
end
