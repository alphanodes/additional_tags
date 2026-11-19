# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class FieldListTagsTest < AdditionalTags::TestCase
  # A list macro over issues which knows the tags filter only
  class IssueList < Additionals::FieldList
    include AdditionalTags::FieldListTags

    class Source < Additionals::FieldTemplateSource
      def placeholders = { 'subject' => :field_subject }
      def attribute_value(issue, name) = name == 'subject' ? issue.subject : super
    end

    def initialize(args, issues:)
      @issue_ids = issues.map(&:id)
      super(args)
    end

    private

    def reserved_options = %w[sort]
    def default_template = '- {%subject%}'
    def block_language = 'issue_list'
    def available_fields = []
    def default_sort_value(issue) = issue.subject
    def renderer = Additionals::FieldTemplate.new(Source.new)

    def records
      @filters.inject(Issue.where(id: @issue_ids)) { |scope, filter| filter_by_tags scope, filter }
    end
  end

  def setup
    prepare_tests
    User.current = users :users_001

    @issues = issues :issues_001, :issues_002, :issues_003
    @issues.each { |issue| issue.update! tag_list: [] }
    @issues.first.update! tag_list: %w[Urgent Backend]
    @issues.second.update! tag_list: %w[Backend]
  end

  def test_filters_by_tags_with_the_operators_of_a_list
    assert_equal [subject(0)], listed('tags=urgent')
    assert_equal [subject(1), subject(2)].sort, listed('tags!=Urgent')
    assert_equal [subject(0), subject(1)].sort, listed('tags=Urgent|Backend')
    assert_equal [subject(2)], listed('tags=none')
    assert_equal [subject(0), subject(1)].sort, listed('tags=any')
  end

  # A tag is a name and is never looked into
  def test_refuses_contains
    error = assert_raises Additionals::FieldList::Error do
      listed 'tags~Urg'
    end

    assert_equal :error_field_list_operator_not_supported, error.key
  end

  private

  def listed(*args)
    IssueList.new(args, issues: @issues).to_wiki_text.split("\n").map { |line| line.delete_prefix '- ' }
  end

  def subject(index)
    @issues[index].subject
  end
end
