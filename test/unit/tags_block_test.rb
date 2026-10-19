# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

# The shared tags block with the hooks a subclass names: the issues of a
# project per tag, by tracker as statuses or without statuses
class TagsBlockTest < AdditionalTags::TestCase
  def setup
    prepare_tests
    User.current = users :users_001
    @project = projects :projects_001
    @tracker_ids = Tracker.sorted.ids
  end

  def test_columns_are_the_statuses_and_the_total
    assert_equal [*Tracker.sorted.map(&:name), I18n.t(:label_total)], by_tracker.data.columns
  end

  def test_cells_are_the_entries_per_status
    row = by_tracker.data.rows.first

    assert_equal(@tracker_ids.map { |id| tagged_issues(row.tag).where(tracker_id: id).count },
                 row.cells.map(&:count))
  end

  def test_cells_name_their_status
    assert_equal @tracker_ids, by_tracker.data.rows.first.cells.map(&:status_id)
  end

  def test_statuses_add_up_to_the_total
    assert_equal(by_tracker.data.rows.map(&:total), by_tracker.data.rows.map { |row| row.cells.sum(&:count) })
  end

  def test_only_one_status_has_one_column
    assert_equal [I18n.t(:label_quantity)], by_tracker(only_status: @tracker_ids.first).data.columns
  end

  def test_only_one_status_counts_the_entries_of_the_status
    tag = by_tracker.data.rows.first.tag

    assert_equal tagged_issues(tag).where(tracker_id: @tracker_ids.first).count,
                 by_tracker(only_status: @tracker_ids.first).data.rows.first.total
  end

  def test_without_statuses_there_is_one_column
    assert_equal [I18n.t(:label_quantity)], without_statuses.data.columns
  end

  def test_without_statuses_rows_have_no_cells
    assert_empty without_statuses.data.rows.flat_map(&:cells)
  end

  def test_without_statuses_the_total_counts_the_entries_of_the_tag
    row = without_statuses.data.rows.first

    assert_equal tagged_issues(row.tag).count, row.total
  end

  def test_rows_follow_the_sort_order_of_the_settings
    with_plugin_settings 'additional_tags', tags_sort_by: 'name', tags_sort_order: 'desc' do
      names = without_statuses.data.rows.map { |row| row.tag.name }

      assert_equal AdditionalTag.sort_tags(names.dup).reverse, names
    end
  end

  def test_without_tags_nothing_is_counted
    assert_equal 0, without_statuses(available_tags: []).data.count
  end

  def test_counts_with_the_list_without_its_default_status_filter
    tagged = Issue.visible.where id: AdditionalTagging.where(taggable_type: 'Issue').select(:taggable_id)

    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      assert_equal tagged.where(project: @project.self_and_descendants).count, without_statuses.data.count
    end
  end

  # The default filter of the issue list are the open issues
  def test_only_one_status_counts_with_the_default_status_filter_of_the_list
    tagged = Issue.open.visible.where id: AdditionalTagging.where(taggable_type: 'Issue').select(:taggable_id)

    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      assert_equal tagged.where(project: @project.self_and_descendants).count,
                   without_statuses(only_status: 'o', one_status_key: :total).data.count
    end
  end

  def test_links_go_to_the_list_of_the_tag
    assert_equal({ tag_action: 'index', tag_controller: 'issues', filter: nil }, by_tracker.tag_link_options)
  end

  def test_links_of_a_status_filter_the_list_for_it
    assert_equal({ field: :tracker_id, operator: '=', value: [@tracker_ids.last.to_s] },
                 by_tracker.tag_link_options(@tracker_ids.last)[:filter])
  end

  def test_links_of_only_one_status_filter_the_list_for_it
    assert_equal({ field: :tracker_id, operator: '=', value: [@tracker_ids.first.to_s] },
                 by_tracker(only_status: @tracker_ids.first).tag_link_options[:filter])
  end

  def test_export_names_the_columns_after_the_tag_name
    assert_equal [I18n.t(:field_name), *by_tracker.data.columns], by_tracker.export_data[:columns]
  end

  def test_export_has_the_tag_its_cells_and_its_total_per_row
    row = by_tracker.data.rows.first

    assert_equal [row.tag.name, *row.cells.map(&:count), row.total], by_tracker.export_data[:rows].first
  end

  def test_export_without_statuses_has_the_tag_and_its_total_per_row
    row = without_statuses.data.rows.first

    assert_equal [row.tag.name, row.total], without_statuses.export_data[:rows].first
  end

  def test_export_has_the_count
    assert_equal without_statuses.data.count, without_statuses.export_data[:count]
  end

  private

  # Trackers as statuses, filtered by tracker in the issue list
  def by_tracker(**hooks)
    statuses = Tracker.sorted.to_h { |tracker| [tracker.id, tracker.name.to_sym] }
    project = @project
    tags_block(statuses:,
               count_scope: Issue.visible.where(project:).joins(:tags).group(:tracker_id, 'tag_id').count,
               status_field: :tracker_id,
               status_label: ->(_status_id, key) { key.to_s },
               **hooks)
  end

  def without_statuses(**hooks)
    project = @project
    tags_block(count_scope: Issue.visible.where(project:).joins(:tags).group('tag_id').count, **hooks)
  end

  def tags_block(**hooks)
    project = @project
    hooks = { available_tags: Issue.available_tags(project:),
              query_class: IssueQuery,
              count_method: :issue_count,
              tag_controller: 'issues' }.merge(hooks)
    block_class = Class.new DashboardBlocks::TagsBlock do
      hooks.each do |name, value|
        value.is_a?(Proc) ? define_method(name, &value) : define_method(name) { |*| value }
      end
    end
    block_class.new DashboardContentProject.new(project:)
  end

  def tagged_issues(tag)
    Issue.visible.where(project: @project).joins(:tags).where(AdditionalTag.table_name => { id: tag.id })
  end
end
