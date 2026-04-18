# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TaggingModelTest < AdditionalTags::TestCase
  def test_table_name
    assert_equal 'additional_taggings', AdditionalTagging.table_name
  end

  def test_default_context_constant
    assert_equal 'tags', AdditionalTagging::DEFAULT_CONTEXT
  end

  def test_belongs_to_tag
    reflection = AdditionalTagging.reflect_on_association :tag

    assert_not_nil reflection
    assert_equal :belongs_to, reflection.macro
  end

  def test_belongs_to_taggable_polymorphic
    reflection = AdditionalTagging.reflect_on_association :taggable

    assert_not_nil reflection
    assert_equal :belongs_to, reflection.macro
    assert reflection.options[:polymorphic]
  end

  def test_validates_presence_of_context
    tagging = AdditionalTagging.new tag_id: 1,
                                    taggable_id: 1,
                                    taggable_type: 'Issue',
                                    context: nil

    assert_not tagging.valid?
    assert_includes tagging.errors[:context], 'cannot be blank'
  end

  def test_validates_presence_of_tag_id
    tagging = AdditionalTagging.new taggable_id: 1,
                                    taggable_type: 'Issue',
                                    context: 'tags',
                                    tag_id: nil

    assert_not tagging.valid?
    assert_includes tagging.errors[:tag_id], 'cannot be blank'
  end

  def test_validates_uniqueness_of_tag_id
    issue = issues :issues_002
    tag = AdditionalTag.first

    original = AdditionalTagging.create! tag_id: tag.id,
                                         taggable: issue,
                                         context: 'tags'
    duplicate = AdditionalTagging.new tag_id: tag.id,
                                      taggable: issue,
                                      context: 'tags'

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], 'has already been taken'
  ensure
    original&.destroy
  end

  def test_uniqueness_allows_different_context
    issue = issues :issues_002
    tag = AdditionalTag.first

    tagging_a = AdditionalTagging.create! tag_id: tag.id,
                                          taggable: issue,
                                          context: 'tags'
    tagging_b = AdditionalTagging.new tag_id: tag.id,
                                      taggable: issue,
                                      context: 'other'

    assert tagging_b.valid?
  ensure
    tagging_a&.destroy
  end

  def test_uniqueness_allows_different_taggable
    tag = AdditionalTag.first

    tagging_a = AdditionalTagging.create! tag_id: tag.id,
                                          taggable: issues(:issues_002),
                                          context: 'tags'
    tagging_b = AdditionalTagging.new tag_id: tag.id,
                                      taggable: issues(:issues_003),
                                      context: 'tags'

    assert tagging_b.valid?
  ensure
    tagging_a&.destroy
  end

  def test_scope_by_context
    result = AdditionalTagging.by_context 'tags'

    assert_kind_of ActiveRecord::Relation, result
    assert(result.all? { |t| t.context == 'tags' })
  end

  def test_scope_by_context_excludes_other
    issue = issues :issues_002
    tag = AdditionalTag.first
    other = AdditionalTagging.create! tag_id: tag.id,
                                      taggable: issue,
                                      context: 'skills'

    result = AdditionalTagging.by_context 'tags'

    assert_not_includes result.to_a, other
  ensure
    other&.destroy
  end

  def test_scope_not_owned
    result = AdditionalTagging.not_owned

    assert_kind_of ActiveRecord::Relation, result
    assert(result.all? { |t| t.tagger_id.nil? && t.tagger_type.nil? })
  end

  def test_scope_not_owned_excludes_owned
    issue = issues :issues_002
    tag = AdditionalTag.first
    owned = AdditionalTagging.create! tag_id: tag.id,
                                      taggable: issue,
                                      context: 'tags',
                                      tagger_id: 1,
                                      tagger_type: 'User'

    result = AdditionalTagging.not_owned

    assert_not_includes result.to_a, owned
  ensure
    owned&.destroy
  end
end
