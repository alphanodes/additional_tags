# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__

class AdditionalTagsHelperTest < AdditionalTags::HelperTest
  def setup
    super
    @redmine_view = build_redmine_view IssuesController
  end

  # The order itself is tested with AdditionalTag.sort_for_list
  def test_sort_tags_for_list_sorts_like_the_model
    tags = tags_with_counts 'Zebra' => 1, 'Mango' => 2, 'äpfel' => 1

    assert_equal AdditionalTag.sort_for_list(tags, sort_by: 'count', sort_order: 'desc').map(&:name),
                 @redmine_view.sort_tags_for_list(tags, sort_by: 'count', sort_order: 'desc').map(&:name)
  end

  # The group itself is tested with AdditionalTag#title_group, against the
  # same table as the titles of select fields (tags.js)
  def test_tag_link_titles_scoped_and_grouped_tags_with_colors
    cases = { ['Prio::High', true] => 'Scoped tag, only one value for: Prio',
              ['Plugin:HRM', true] => 'Grouped tag, group: Plugin',
              ['Bug', true] => nil,
              ['Prio::High', false] => nil }

    titles = I18n.with_locale :en do
      cases.keys.map do |name, use_colors|
        html = @redmine_view.additional_tag_link AdditionalTag.new(name:), link: '#', use_colors: use_colors
        Nokogiri::HTML.fragment(html).at('span')['title']
      end
    end

    assert_equal cases.values, titles
  end

  def test_tag_field_label_explains_grouped_tags_only_with_colors
    scoped = 'Name::value is a scoped tag: only one value per name is allowed.'
    grouped = 'Name:value is a grouped tag: all tags with the same name share one color.'

    I18n.with_locale :en do
      { '1' => "#{grouped} #{scoped}", '0' => scoped }.each do |theme, hint|
        with_plugin_settings 'additional_tags', tags_color_theme: theme do
          label = Nokogiri::HTML.fragment(@redmine_view.additional_tags_label_tag(:issue_tag_list)).at('label')

          assert_equal ['issue_tag_list', 'Tags', hint],
                       [label['for'], label.at('span.field-description').text, label.at('span')['title']], theme
        end
      end
    end
  end

  private

  # Tags as available_tags returns them, with the count as selected column
  def tags_with_counts(counts)
    counts.map { |name, count| AdditionalTag.instantiate 'name' => name, 'count' => count }
  end
end
