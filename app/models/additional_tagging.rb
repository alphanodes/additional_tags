# frozen_string_literal: true

class AdditionalTagging < ApplicationRecord
  DEFAULT_CONTEXT = 'tags'

  belongs_to :tag, class_name: 'AdditionalTag', counter_cache: :taggings_count
  belongs_to :taggable, polymorphic: true
  belongs_to :tagger, polymorphic: true, optional: true

  validates :context, presence: true
  validates :tag_id, presence: true
  validates :tag_id, uniqueness: { scope: %i[taggable_type taggable_id context tagger_id tagger_type] }

  scope :by_context, ->(context = DEFAULT_CONTEXT) { where context: context.to_s }
  scope :not_owned, -> { where tagger_id: nil, tagger_type: nil }
end
