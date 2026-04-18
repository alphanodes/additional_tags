# frozen_string_literal: true

class AdditionalTagging < ApplicationRecord
  belongs_to :tag, class_name: 'AdditionalTag', counter_cache: :taggings_count
  belongs_to :taggable, polymorphic: true
  belongs_to :tagger, polymorphic: true, optional: true

  validates :tag_id, presence: true
  validates :tag_id, uniqueness: { scope: %i[taggable_type taggable_id tagger_id tagger_type] }

  scope :not_owned, -> { where tagger_id: nil, tagger_type: nil }
end
