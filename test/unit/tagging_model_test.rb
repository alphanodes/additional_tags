# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class TaggingModelTest < AdditionalTags::TestCase
  def test_table_name
    assert_equal 'additional_taggings', AdditionalTagging.table_name
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

  def test_taggable_belongs_to_is_required
    # Guards against accidental removal of `optional: false` on the polymorphic
    # belongs_to. The option must be explicitly present and false, because
    # Redmine sets belongs_to_required_by_default to false - so an absent
    # :optional key would silently make the validation disappear.
    reflection = AdditionalTagging.reflect_on_association :taggable

    assert reflection.options.key?(:optional), ':optional must be set explicitly'
    assert_not reflection.options[:optional]
  end

  def test_validates_presence_of_tag_id
    tagging = AdditionalTagging.new tag_id: nil, taggable: issues(:issues_002)

    assert_not tagging.valid?
    assert_includes tagging.errors[:tag_id], 'cannot be blank'
  end

  def test_validates_presence_of_taggable
    tag = AdditionalTag.first
    tagging = AdditionalTagging.new tag_id: tag.id

    assert_not tagging.valid?
    assert_includes tagging.errors[:taggable], 'must exist'
  end

  def test_validates_presence_of_taggable_id_only
    tag = AdditionalTag.first
    tagging = AdditionalTagging.new tag_id: tag.id, taggable_type: 'Issue', taggable_id: nil

    assert_not tagging.valid?
    assert_includes tagging.errors[:taggable], 'must exist'
  end

  def test_validates_presence_of_taggable_type_only
    tag = AdditionalTag.first
    tagging = AdditionalTagging.new tag_id: tag.id, taggable_type: nil, taggable_id: 1

    assert_not tagging.valid?
    assert_includes tagging.errors[:taggable], 'must exist'
  end

  def test_validates_uniqueness_of_tag_id
    issue = issues :issues_002
    tag = AdditionalTag.first

    original = AdditionalTagging.create! tag_id: tag.id,
                                         taggable: issue
    duplicate = AdditionalTagging.new tag_id: tag.id,
                                      taggable: issue

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], 'has already been taken'
  ensure
    original&.destroy
  end

  def test_uniqueness_allows_different_taggable
    tag = AdditionalTag.first

    tagging_a = AdditionalTagging.create! tag_id: tag.id,
                                          taggable: issues(:issues_002)
    tagging_b = AdditionalTagging.new tag_id: tag.id,
                                      taggable: issues(:issues_003)

    assert tagging_b.valid?
  ensure
    tagging_a&.destroy
  end
end
