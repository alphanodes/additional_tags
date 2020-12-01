module AdditionalTagsWikiHelper
  def sidebar_tags
    unless @sidebar_tags
      @sidebar_tags = []
      @sidebar_tags = WikiPage.available_tags(project: @project) if AdditionalTags.show_sidebar_tags?
    end
    @sidebar_tags
  end

  def render_sidebar_tags
    render_tags_list sidebar_tags,
                     show_count: AdditionalTags.setting?(:show_with_count),
                     style: AdditionalTags.setting(:tags_sidebar).to_sym,
                     link_wiki_tag: true,
                     project: @project
  end
end
