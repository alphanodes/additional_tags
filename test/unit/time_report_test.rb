# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TimeReportTest < AdditionalTags::TestCase
  def setup
    prepare_tests
    User.current = users :users_002
    @project = projects :projects_001
  end

  def test_available_criteria_add_tags_and_keep_core_criteria
    criteria = time_report.available_criteria

    assert criteria.key?('tags')
    assert_equal AdditionalTag, criteria['tags'][:klass]
    assert_equal :field_tags, criteria['tags'][:label]

    # everything Redmine core offers has to survive the patch
    assert criteria.key?('project')
    assert criteria.key?('user')
    assert criteria.key?('activity')
  end

  def test_report_can_be_grouped_by_tags
    report = time_report ['tags']

    assert_equal ['tags'], report.criteria
    assert_not_nil report.hours
  end

  private

  def time_report(criteria = [])
    Redmine::Helpers::TimeReport.new @project, criteria, 'month', TimeEntry.visible.where(project_id: @project.id)
  end
end
