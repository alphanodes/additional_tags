# frozen_string_literal: true

class MigrateTag < Rails.version < '7.1' ? ActiveRecord::Base : ApplicationRecord
  self.table_name = 'tags'
  has_many :migrate_taggings, dependent: :destroy, foreign_key: :tag_id, inverse_of: :migrate_tag
end
