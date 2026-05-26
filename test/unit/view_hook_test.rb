# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class ViewHookTest < AdditionalTags::TestCase
  def setup
    @hook = AdditionalTags::Hooks::ViewHook.instance
    User.current = users :users_001
  end

  def test_bulk_tags_fix_uses_bulk_copy_source_tag_list_when_set
    # Simulates a bulk-copy scenario: copy_from has set
    # bulk_copy_source_tag_list, then safe_attributes= has overwritten
    # @tag_list with the user's params value. The hook must recover the
    # source tags from the accessor, not from the overwritten @tag_list.
    issue = Issue.new
    issue.bulk_copy_source_tag_list = %w[Alpha Beta]
    issue.tag_list = ['bulk_tag']

    params = { issue: { tag_list: ['bulk_tag'] } }
    @hook.send :issues_bulk_tags_fix, issue, params

    assert_equal %w[Alpha Beta bulk_tag], issue.tag_list.to_a.sort
  end

  def test_bulk_tags_fix_falls_back_to_tags_association_for_persisted_issue
    # Persisted issue, no copy_from involved (bulk_copy_source_tag_list is
    # nil). The hook must read existing tags from the tags association,
    # which still holds the pre-update DB state.
    issue = issues :issues_001 # fixture has tag "First"

    params = { issue: { tag_list: ['NewTag'] } }
    @hook.send :issues_bulk_tags_fix, issue, params

    assert_equal %w[First NewTag], issue.tag_list.to_a.sort
  end

  def test_bulk_tags_fix_removes_common_tags_and_adds_new
    issue = Issue.new
    issue.bulk_copy_source_tag_list = %w[A B C]

    params = { issue: { tag_list: ['D'] }, common_tags: 'A,C' }
    @hook.send :issues_bulk_tags_fix, issue, params

    # tags_to_add = [D] - [A,C] = [D]
    # tags_to_remove = [A,C] - [D] = [A,C]
    # Result: source [A,B,C] - removed [A,C] + added [D] = [B, D]
    assert_equal %w[B D], issue.tag_list.to_a.sort
  end

  def test_bulk_tags_fix_handles_blank_common_tags_param
    issue = Issue.new
    issue.bulk_copy_source_tag_list = %w[Source]

    params = { issue: { tag_list: ['Added'] } } # no :common_tags key
    @hook.send :issues_bulk_tags_fix, issue, params

    assert_equal %w[Added Source], issue.tag_list.to_a.sort
  end

  def test_bulk_tags_fix_is_noop_when_params_is_nil
    issue = Issue.new
    issue.tag_list = ['unchanged']

    @hook.send :issues_bulk_tags_fix, issue, nil

    assert_equal ['unchanged'], issue.tag_list.to_a
  end

  def test_bulk_tags_fix_is_noop_when_params_lacks_issue_key
    issue = Issue.new
    issue.tag_list = ['unchanged']

    @hook.send :issues_bulk_tags_fix, issue, { other_key: 'foo' }

    assert_equal ['unchanged'], issue.tag_list.to_a
  end

  def test_bulk_tags_fix_treats_empty_bulk_copy_source_as_a_copy_signal
    # An empty array on bulk_copy_source_tag_list is not the same as nil:
    # it means "this is a copy, source had zero tags". The hook must use
    # the empty list, not fall back to issue.tags.to_a.
    issue = Issue.new
    issue.bulk_copy_source_tag_list = []
    issue.tag_list = []

    params = { issue: { tag_list: ['Brand'] } }
    @hook.send :issues_bulk_tags_fix, issue, params

    assert_equal ['Brand'], issue.tag_list.to_a
  end
end
