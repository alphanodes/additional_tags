# frozen_string_literal: true

class AdditionalTagging < ApplicationRecord
  belongs_to :tag, class_name: 'AdditionalTag', counter_cache: :taggings_count
  belongs_to :taggable, polymorphic: true

  validates :tag_id,
            presence: true,
            uniqueness: { scope: %i[taggable_type taggable_id] }
end
