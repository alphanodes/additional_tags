# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

# The tags of the issues as dashboard block: the table of values with the
# issues per tag and status, as the block shows it and programs read it
class IssueTagsBlockTest < AdditionalTags::TestCase
  def setup
    prepare_tests
    User.current = users :users_001
    @project = projects :projects_001
  end

  def test_columns_are_open_closed_and_total
    assert_equal [I18n.t(:label_open_issues_plural), I18n.t(:label_closed_issues_plural), I18n.t(:label_total)],
                 block.data.columns
  end

  def test_open_issues_only_have_one_column
    assert_equal [I18n.t(:label_quantity)], block(open_issues_only: '1').data.columns
  end

  def test_a_row_per_tag
    assert_equal(Issue.available_tags(project: @project).to_set(&:name), block.data.rows.to_set { |row| row.tag.name })
  end

  def test_open_and_closed_add_up_to_the_total
    row = block.data.rows.first

    assert_equal row.total, row.cells.sum(&:count)
  end

  def test_open_issues_only_count_the_open_ones
    tag = block.data.rows.first.tag
    open = block.data.rows.first.cells.first.count

    assert_equal open, block(open_issues_only: '1').data.rows.detect { |row| row.tag == tag }&.total.to_i
  end

  def test_counts_the_issues_with_tags
    tagged = Issue.visible.where id: AdditionalTagging.where(taggable_type: 'Issue').select(:taggable_id)

    # The block is offered with issue tags only, the filter of the list as well
    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      assert_equal tagged.where(project: @project.self_and_descendants).count, block.data.count
    end
  end

  def test_open_issues_only_count_the_issues_of_the_list_behind_the_total
    tags_block = block open_issues_only: '1'

    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      assert_equal list_count(tags_block), tags_block.data.count
    end
  end

  def test_counts_the_issues_of_the_list_behind_the_total
    with_plugin_settings 'additional_tags', active_issue_tags: '1' do
      assert_equal list_count(block), block.data.count
    end
  end

  def test_total_links_to_the_issues_of_all_statuses
    assert_equal '*', block.totals_params[:status_id]
  end

  def test_total_of_open_issues_only_links_to_the_open_ones
    assert_equal 'o', block(open_issues_only: '1').totals_params[:status_id]
  end

  def test_cells_are_open_then_closed
    assert_equal [false, true], block.data.rows.first.cells.map(&:status_id)
  end

  def test_not_available_without_issue_tags
    with_plugin_settings 'additional_tags', active_issue_tags: '0' do
      assert_not block.available?
    end
  end

  def test_export_of_open_issues_only_has_the_tag_and_its_quantity
    assert_equal [I18n.t(:field_name), I18n.t(:label_quantity)], block(open_issues_only: '1').export_data[:columns]
  end

  def test_export_has_a_value_per_column
    data = block.export_data

    assert_equal [data[:columns].size] * data[:rows].size, data[:rows].map(&:size)
  end

  def test_export_names_the_tag_first
    assert_equal block.data.rows.map { |row| row.tag.name }, block.export_data[:rows].map(&:first)
  end

  def test_links_of_closed_issues_filter_the_closed_ones
    assert_equal({ field: :status_id, operator: 'c' }, block.tag_link_options(true)[:filter])
  end

  def test_links_of_open_issues_filter_the_open_ones
    assert_equal({ field: :status_id, operator: 'o' }, block.tag_link_options(false)[:filter])
  end

  def test_links_of_open_issues_only_filter_the_open_ones
    assert_equal({ field: :status_id, operator: 'o' }, block(open_issues_only: '1').tag_link_options[:filter])
  end

  def test_links_of_the_total_do_not_filter_the_status
    assert_nil block.tag_link_options[:filter]
  end

  def test_links_go_to_the_issue_list
    assert_equal 'issues', block.tag_link_options[:tag_controller]
  end

  private

  def block(**settings)
    DashboardContentProject.new(project: @project).dashboard_block 'issue_tags', settings:
  end

  def list_count(tags_block)
    query = IssueQuery.new project: @project, name: '_'
    query.build_from_params tags_block.totals_params.with_indifferent_access
    query.issue_count
  end
end
