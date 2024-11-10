# frozen_string_literal: true

class MigrateTagging < ApplicationRecord
  self.table_name = 'taggings'
  belongs_to :migrate_tag, foreign_key: :tag_id, inverse_of: :migrate_taggings
  belongs_to :taggable, polymorphic: true
end
