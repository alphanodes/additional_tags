# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TaggableTest < AdditionalTags::TestCase
  def setup
    User.stubs(:current).returns(users(:users_001))
    @issue = issues :issues_001
    @issue.tag_list = []
    @issue.save!
    @issue.reload
  end

  def test_tag_list_on_new_issue_is_empty
    issue = Issue.new

    assert_empty issue.tag_list
  end

  def test_tag_list_is_additional_tags_tag_list_instance
    assert_kind_of AdditionalTags::TagList, @issue.tag_list
  end

  def test_tag_list_setter_with_array
    @issue.tag_list = %w[ruby rails]

    assert_save @issue

    @issue.reload

    assert_sorted_equal %w[ruby rails], @issue.tag_list.to_a
  ensure
    cleanup_tags 'ruby', 'rails'
  end

  def test_tag_list_setter_with_string
    @issue.tag_list = 'ruby, rails'

    assert_save @issue

    @issue.reload

    assert_sorted_equal %w[ruby rails], @issue.tag_list.to_a
  ensure
    cleanup_tags 'ruby', 'rails'
  end

  def test_tag_list_setter_creates_tags_in_database
    assert_difference 'AdditionalTag.count', 2 do
      @issue.tag_list = %w[new_tag_alpha new_tag_beta]

      assert_save @issue
    end
  ensure
    cleanup_tags 'new_tag_alpha', 'new_tag_beta'
  end

  def test_tag_list_setter_removes_old_tags
    @issue.tag_list = %w[old_tag]

    assert_save @issue

    @issue.reload
    @issue.tag_list = %w[new_tag]

    assert_save @issue

    @issue.reload

    assert_equal %w[new_tag], @issue.tag_list.to_a
    assert_not_includes @issue.tag_list, 'old_tag'
  ensure
    cleanup_tags 'old_tag', 'new_tag'
  end

  def test_tag_list_changed_is_false_when_unchanged
    @issue.tag_list = %w[stable_tag]

    assert_save @issue

    @issue.reload

    assert_not @issue.tag_list_changed?
  ensure
    cleanup_tags 'stable_tag'
  end

  def test_tag_list_changed_is_true_after_modification
    @issue.tag_list = %w[before_tag]

    assert_save @issue

    @issue.reload
    @issue.tag_list = %w[after_tag]

    assert @issue.tag_list_changed?
  ensure
    cleanup_tags 'before_tag', 'after_tag'
  end

  def test_tag_list_was_returns_previous_value
    @issue.tag_list = %w[original]

    assert_save @issue

    @issue.reload
    @issue.tag_list = %w[changed]

    assert_equal %w[original], @issue.tag_list_was.to_a
  ensure
    cleanup_tags 'original', 'changed'
  end

  def test_tags_association_returns_tag_objects
    @issue.tag_list = %w[assoc_tag]

    assert_save @issue

    @issue.reload
    tags = @issue.tags

    assert_not_empty tags
    assert_kind_of ActiveRecord::Base, tags.first
    assert_equal 'assoc_tag', tags.first.name
  ensure
    cleanup_tags 'assoc_tag'
  end

  def test_taggings_association_returns_tagging_objects_with_context
    @issue.tag_list = %w[ctx_tag]

    assert_save @issue

    @issue.reload
    taggings = @issue.taggings

    assert_not_empty taggings

    assert(taggings.all? { |t| t.context == 'tags' })
  ensure
    cleanup_tags 'ctx_tag'
  end

  def test_tagged_with_finds_tagged_issues
    @issue.tag_list = %w[findme]

    assert_save @issue

    results = Issue.tagged_with 'findme'

    assert_includes results.to_a, @issue
  ensure
    cleanup_tags 'findme'
  end

  def test_tagged_with_any_option
    issue_a = issues :issues_002
    issue_b = issues :issues_003

    issue_a.tag_list = %w[alpha]

    assert_save issue_a

    issue_b.tag_list = %w[beta]

    assert_save issue_b

    results = Issue.tagged_with %w[alpha beta], any: true

    assert_includes results.to_a, issue_a
    assert_includes results.to_a, issue_b
  ensure
    cleanup_tags 'alpha', 'beta'
  end

  def test_tagged_with_all_tags_required
    issue_both = issues :issues_002
    issue_one = issues :issues_003

    issue_both.tag_list = %w[x_all y_all]

    assert_save issue_both

    issue_one.tag_list = %w[x_all]

    assert_save issue_one

    results = Issue.tagged_with %w[x_all y_all]

    assert_includes results.to_a, issue_both
    assert_not_includes results.to_a, issue_one
  ensure
    cleanup_tags 'x_all', 'y_all'
  end

  def test_tagged_with_returns_active_record_relation
    result = Issue.tagged_with 'nonexistent_tag'

    assert_kind_of ActiveRecord::Relation, result
  end

  def test_save_without_tag_change_does_not_trigger_tag_queries
    @issue.tag_list = %w[perf_tag]

    assert_save @issue

    @issue.reload

    tag_queries = 0
    subscriber = ActiveSupport::Notifications.subscribe 'sql.active_record' do |_name, _started, _finished, _unique_id, data|
      tag_queries += 1 if data[:sql].include? 'additional_tag'
    end

    @issue.subject = 'Updated subject'

    assert_save @issue
    assert_equal 0, tag_queries
  ensure
    ActiveSupport::Notifications.unsubscribe subscriber if subscriber
    cleanup_tags 'perf_tag'
  end

  private

  def cleanup_tags(*names)
    @issue&.reload
    @issue&.update_column :updated_on, Time.current
    names.each do |name|
      tag = AdditionalTag.find_by name: name
      next unless tag

      AdditionalTagging.where(tag_id: tag.id).delete_all
      tag.destroy
    end
  end
end
