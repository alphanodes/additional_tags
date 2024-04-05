# frozen_string_literal: true

module AdditionalTagsHelper
  include ActsAsTaggableOn::TagsHelper

  def format_tags_json(tags)
    tags.map do |tag|
      {
        'id' => tag.name,
        'text' => tag.name
      }
    end
  end

  def manageable_tags
    AdditionalTags::Tags.sort_tag_list ActsAsTaggableOn::Tag.where({})
  end

  def manageable_tag_columns
    return @manageable_tag_columns if defined? @manageable_tag_columns

    columns = {}

    if AdditionalTags.setting? :active_issue_tags
      columns[:issue] = { label: l(:label_issue_plural),
                          tag_controller: :issues,
                          counts: Issue.available_tags.to_h { |tag| [tag.id, tag.count] } }
    end

    if AdditionalTags.setting? :active_wiki_tags
      columns[:wiki] = { label: l(:label_wiki),
                         counts: WikiPage.available_tags.to_h { |tag| [tag.id, tag.count] } }
    end

    call_hook :helper_additional_manageable_tag_columns, columns: columns

    @manageable_tag_columns = columns
  end

  def manageable_tag_column_values(tag)
    columns = []
    manageable_tag_columns.each_value do |column_values|
      cnt = column_values[:counts][tag.id]
      cnt = 0 if cnt.blank?

      columns << if cnt.positive? && column_values[:tag_controller]
                   link_to cnt, tag_url(tag.name, tag_controller: column_values[:tag_controller])
                 else
                   cnt
                 end
    end
    columns
  end

  def values_for_sort_direction
    [[l(:label_ascending), 'asc'], [l(:label_descending), 'desc']]
  end

  def sort_tags_for_list(tags, sort_by: nil, sort_order: nil)
    return tags if tags.size < 2

    sort_by = AdditionalTags.setting :tags_sort_by if sort_by.blank?
    sort_order = AdditionalTags.setting :tags_sort_order if sort_order.blank?

    case "#{sort_by}:#{sort_order}"
    when 'name:desc'
      tags = AdditionalTags::Tags.sort_tag_list(tags).reverse
    when 'count:asc'
      tags.sort_by!(&:count)
    when 'count:desc'
      tags.sort! { |a, b| b.count <=> a.count }
    else
      tags = AdditionalTags::Tags.sort_tag_list tags
    end

    tags
  end

  def render_tags_list(tags, **options)
    return if tags.blank?

    options[:show_count] = AdditionalTags.setting? :show_with_count unless options.key? :show_count
    options[:color_theme] = AdditionalTags.setting :tags_color_theme unless options.key? :color_theme
    options[:use_colors] = AdditionalTags.use_colors? unless options.key? :use_colors

    style = options.key?(:style) ? options.delete(:style) : AdditionalTags.setting(:tags_sidebar).to_sym
    tags = tags.all.to_a if tags.respond_to? :all
    tags = sort_tags_for_list tags

    case style
    when :list
      list_el = 'ul'
      item_el = 'li'
    when :simple_cloud, :cloud
      list_el = 'div'
      item_el = 'span'
    else
      raise 'Unknown list style'
    end

    content = +''.html_safe
    if style == :list && AdditionalTags.setting(:tags_sort_by) == 'name'
      tags.group_by { |tag| tag.name.downcase.first }.each do |letter, grouped_tags|
        content << content_tag(item_el, letter.upcase, class: 'letter')
        add_tags style, grouped_tags, content, item_el, options
      end
    else
      add_tags style, tags, content, item_el, options
    end

    content_tag(list_el, content, class: 'tags-cloud', style: (style == :simple_cloud ? 'text-align: left;' : ''))
  end

  def additional_tag_link(tag_object,
                          link: nil,
                          link_wiki_tag: false,
                          show_count: false,
                          use_colors: nil,
                          name: nil,
                          color_theme: nil,
                          **options)
    options[:project] = @project if options[:project].blank? && @project.present?
    if !options.key?(:display_type) && @query && @query.display_type != @query.default_display_type
      options[:display_type] = @query.display_type
    end

    use_colors = AdditionalTags.use_colors? if use_colors.nil?
    color_theme = AdditionalTags.setting :tags_color_theme if color_theme.nil?

    tag_info = AdditionalTag.new name: name.nil? ? tag_object.name : name,
                                 disable_grouping: !use_colors,
                                 color_theme: color_theme
    tag_name = [tag_info.tag_name]

    tag_style = "background-color: #{tag_info.tag_bg_color}; color: #{tag_info.tag_fg_color}" if use_colors

    if tag_info.scoped?
      tag_name << if show_count
                    tag.span tag_info.group_value, class: 'tag-group-value'
                  else
                    tag.span tag_info.group_value, class: 'tag-group-value tag-group-nocount'
                  end
    end

    tag_name << tag.span(tag_object.count, class: 'tag-count') if show_count

    content = if link
                link_to safe_join(tag_name),
                        link,
                        style: tag_style
              elsif link_wiki_tag
                link = if options[:project].present?
                         project_wiki_index_path options[:project], tag: tag_object.name
                       else
                         wiki_path tag_object.name
                       end
                link_to safe_join(tag_name), link, style: tag_style
              else
                link_to safe_join(tag_name),
                        tag_url(tag_object.name, **options),
                        style: tag_style
              end

    style = if use_colors
              { class: 'additional-tag-label-color', style: tag_style }
            else
              { class: 'tag-label' }
            end

    tag.span content, **style
  end

  # plain list of tags
  def additional_plain_tag_list(tags, sep: nil)
    sep ||= "#{Query.additional_csv_separator} "

    s = tags.present? ? tags.map(&:name) : ['']
    s.join sep
  end

  def additional_tag_sep(use_colors: true)
    use_colors ? ' ' : ', '
  end

  def additional_tags_from_params(str)
    tags = str.is_a?(Array) ? str : str.to_s.split(',')
    tags.map!(&:strip)
    tags.compact_blank
  end

  def additional_tag_links(tag_list, **options)
    return if tag_list.blank?

    unsorted = options.delete :unsorted
    tag_list = AdditionalTags::Tags.sort_tag_list tag_list unless unsorted

    # set defaults if not defined
    options[:use_colors] = AdditionalTags.use_colors? unless options.key? :use_colors
    options[:color_theme] = AdditionalTags.setting :tags_color_theme unless options.key? :color_theme

    safe_join tag_list.map { |tag| additional_tag_link tag, **options },
              additional_tag_sep(use_colors: options[:use_colors])
  end

  def link_to_issue_tags_totals(entries:, project:, open_issues_only:)
    sum = if entries.blank? || entries.empty?
            0
          else
            query = IssueQuery.new project: project, name: '_'
            query.add_filter 'tags', '*'
            query.filters['status_id'][:operator] = '*' if !open_issues_only && query.filters.key?('status_id')

            query.issue_count
          end

    link_to sum, _project_issues_path(project,
                                      set_filter: 1,
                                      tags: '*',
                                      status_id: open_issues_only ? 'o' : '*')
  end

  def issue_tag_status_filter(operator: nil, open_issues_only: false)
    if operator
      { field: :status_id, operator: operator }
    elsif open_issues_only
      { field: :status_id, operator: 'o' }
    end
  end

  private

  def tag_url(tag_name, filter: nil, tag_action: nil, tag_controller: nil, project: nil, display_type: nil)
    action = tag_action.presence || (controller_name == 'hrm_user_resources' ? 'show' : 'index')

    fields = [:tags]
    values = { tags: [tag_name] }
    operators = { tags: '=' }

    if filter.present?
      field = filter[:field]
      fields << field
      operators[field] = filter[:operator]
      values[field] = filter[:value] if filter.key? :value
    end

    { controller: tag_controller.presence || controller_name,
      action: action,
      set_filter: 1,
      display_type: display_type,
      project_id: project,
      f: fields,
      v: values,
      op: operators }
  end

  def add_tags(style, tags, content, item_el, options)
    tag_cloud tags, (1..8).to_a do |tag, weight|
      content << ' '.html_safe + content_tag(item_el,
                                             additional_tag_link(tag, **options),
                                             class: "tag-nube-#{weight}",
                                             style: (style == :simple_cloud ? 'font-size: 1em;' : '')) + ' '.html_safe
    end
  end
end
