# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TagsTest < AdditionalTags::TestCase
  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers,
           :time_entries,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :journals, :journal_details,
           :additional_tags, :additional_taggings

  def setup
    prepare_tests
    @project = projects :projects_001
  end

  def test_available_tags_for_issue
    tags = AdditionalTags::Tags.available_tags Issue
    assert_equal 5, tags.to_a.size
  end

  def test_available_tags_for_issue_with_permission
    tags = AdditionalTags::Tags.available_tags Issue,
                                               user: users(:users_002),
                                               permission: :non_existing

    assert_equal 0, tags.to_a.size
  end

  def test_available_tags_for_wiki_page
    tags = AdditionalTags::Tags.available_tags WikiPage,
                                               project_join: WikiPage.project_joins
    assert_equal 2, tags.to_a.size
  end

  def test_available_tags_for_wiki_page_with_permission
    tags = AdditionalTags::Tags.available_tags WikiPage,
                                               user: users(:users_003),
                                               permission: :view_wiki_pages,
                                               project_join: WikiPage.project_joins
    assert_equal 2, tags.to_a.size
  end

  def test_merge_with_new_tag_name
    tag_name = 'not_existing_tag'

    tags = ActsAsTaggableOn::Tag.where name: %w[First Second]

    issue3 = issues :issues_003
    issue6 = issues :issues_006

    assert_equal %w[Second], issue3.tag_list
    assert_equal %w[Four Second], issue6.tag_list

    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      AdditionalTags::Tags.merge tag_name, tags
    end

    assert_equal [tag_name], Issue.find(3).tag_list
    assert_equal ['Four', tag_name], Issue.find(6).tag_list
  end

  def test_merge_with_exiting_tag_name
    tag_name = 'Four'

    tags = ActsAsTaggableOn::Tag.where name: %w[First Second]

    issue3 = issues :issues_003
    issue6 = issues :issues_006

    assert_equal %w[Second], issue3.tag_list
    assert_equal %w[Four Second], issue6.tag_list

    assert_difference 'ActsAsTaggableOn::Tag.count', -2 do
      AdditionalTags::Tags.merge tag_name, tags
    end

    assert_equal [tag_name], Issue.find(3).tag_list
    assert_equal [tag_name], Issue.find(6).tag_list
  end

  def test_remove_unused_tags
    ActsAsTaggableOn::Tag.create! name: 'unused_new_tag'

    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do
      AdditionalTags::Tags.remove_unused_tags
    end
  end

  def test_add_new_tag_should_increase_count
    issue = issues :issues_002

    assert_difference 'ActsAsTaggableOn::Tag.count', 1 do
      issue.tag_list << 'unused_new_tag'
      issue.save!
    end

    tag = ActsAsTaggableOn::Tag.find_by name: 'unused_new_tag'
    assert_equal 1, tag.taggings_count
  end

  def test_entity_group_by_with_statuses
    counts = AdditionalTags::Tags.entity_group_by scope: { [1, 1] => 1, [2, 1] => 1, [2, 2] => 5, [3, 3] => 10 },
                                                  tags: Issue.available_tags,
                                                  statuses: { 1 => :test1, 2 => :test2 }
    assert_equal 5, counts.size
    first = counts['First']

    assert_equal 1, first[:tag].id
    assert_equal 2, first[:total]
    assert_equal 0, first[:total_sub_groups]
    assert_equal 2, first[:groups].size
    assert 1, first[:test1]
    assert 1, first[:test2]
    assert_equal 2, first[:total_without_sub_groups]

    second = counts['Second']

    assert_equal 2, second[:tag].id
    assert_equal 5, second[:total]
    assert_equal 0, second[:total_sub_groups]
    assert_equal 2, second[:groups].size
    assert 0, second[:test1]
    assert 5, second[:test2]
    assert_equal 5, second[:total_without_sub_groups]
  end

  def test_entity_group_by_with_statuses_and_bool
    counts = AdditionalTags::Tags.entity_group_by scope: Issue.group_by_status_with_tags,
                                                  tags: Issue.available_tags,
                                                  statuses: { true => :closed, false => :open },
                                                  group_id_is_bool: true
    assert_equal 5, counts.size
    first = counts['First']
    assert_equal 1, first[:tag].id
    assert_equal 2, first[:total]
    assert_equal 0, first[:total_sub_groups]
    assert_equal 2, first[:groups].size
    assert_equal 2, first[:total_without_sub_groups]
    assert first[:total] == first[:total_sub_groups] + first[:total_without_sub_groups]
  end

  def test_entity_group_by_without_statuses
    counts = AdditionalTags::Tags.entity_group_by scope: Issue.group_by_status_with_tags,
                                                  tags: Issue.available_tags
    assert_equal 5, counts.size

    first = counts['First']
    assert_equal 1, first[:tag].id
    assert_equal 0, first[:total]
    assert_equal 0, first[:total_sub_groups]
    assert_equal [], first[:groups]
    assert_equal 0, first[:total_without_sub_groups]
  end
end
