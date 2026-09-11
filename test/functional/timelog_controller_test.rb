# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TimelogControllerTest < AdditionalTags::ControllerTest
  def setup
    prepare_tests
  end

  def test_get_report_with_tags
    @request.session[:user_id] = 2

    get :report,
        params: { criteria: ['tags'],
                  set_filter: 1,
                  sort: 'spent_on:desc',
                  f: ['spent_on', ''],
                  op: { spent_on: '*' },
                  t: ['hours', ''],
                  columns: 'month' }

    assert_response :success
    assert_select 'table#time-report tr.last-level td.name'
    assert_select 'table#time-report tr.total', 1
  end

  # The issue_tags column of a time entry is rendered by the prepended
  # column_content as well, and the other columns stay with core.
  def test_index_renders_the_issue_tags_column
    @request.session[:user_id] = 2

    with_plugin_settings 'additional_tags', active_issue_tags: 1 do
      get :index, params: { c: %w[issue issue_tags user] }
    end

    assert_response :success
    assert_select 'table.list.time-entries td.issue_tags a', text: additional_tags(:tag_one).name
    # rendered by core, reached through super
    assert_select 'table.list.time-entries td.user a[href*=?]', '/users/'
  end
end
