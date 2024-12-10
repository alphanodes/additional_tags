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
end
