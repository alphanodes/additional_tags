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

  def render_wiki_index_title(project: nil, name: nil, tag: nil, title: :label_wiki)
    if tag.present?
      tag_object = ActsAsTaggableOn::Tag.new name: tag

      if project
        safe_join [l(:label_wiki_index_for_tag), additional_tag_link(tag_object, link: '#')], ' '
      else
        title = [link_to(l(title), wiki_index_path)]
        title << Additionals::LIST_SEPARATOR
        title << l(:label_wiki_index_for_tag)
        title << additional_tag_link(tag_object, link: '#')
        safe_join title, ' '
      end
    elsif name.present?
      title = [link_to(l(title), wiki_index_path)]
      title << Additionals::LIST_SEPARATOR
      title << name
      safe_join title, ' '
    else
      l title
    end
  end
end
