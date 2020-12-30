module AdditionalTagsWikiHelper
  def sidebar_tags
    unless @sidebar_tags
      @sidebar_tags = []
      @sidebar_tags = WikiPage.available_tags(project: @project) if AdditionalTags.show_sidebar_tags?
    end
    @sidebar_tags
  end

  def render_sidebar_tags
    options = { show_count: AdditionalTags.setting?(:show_with_count),
                style: AdditionalTags.setting(:tags_sidebar).to_sym,
                link_wiki_tag: true,
                project: @project }

    options[:tag_action] = 'show' if %w[wiki_guide].include? controller_name
    render_tags_list sidebar_tags, options
  end
end
