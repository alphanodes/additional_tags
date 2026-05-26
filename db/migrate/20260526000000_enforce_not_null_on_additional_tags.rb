# frozen_string_literal: true

class EnforceNotNullOnAdditionalTags < ActiveRecord::Migration[7.2]
  def up
    # Defensive cleanup: brownfield data may contain NULL/empty rows that the
    # normal code path never produces but custom SQL or older plugin versions
    # might have left behind. Without this, the change_column_null below would
    # fail on such databases.
    execute "DELETE FROM #{AdditionalTagging.table_name} " \
            "WHERE tag_id IN (SELECT id FROM #{AdditionalTag.table_name} WHERE name IS NULL OR name = '')"
    execute "DELETE FROM #{AdditionalTag.table_name} WHERE name IS NULL OR name = ''"
    execute "DELETE FROM #{AdditionalTagging.table_name} " \
            'WHERE tag_id IS NULL OR taggable_id IS NULL ' \
            "OR taggable_type IS NULL OR taggable_type = ''"

    change_column_null :additional_tags, :name, false

    change_table :additional_taggings, bulk: true do |t|
      t.change_null :tag_id, false
      t.change_null :taggable_id, false
      t.change_null :taggable_type, false
    end
  end

  def down
    change_column_null :additional_tags, :name, true

    change_table :additional_taggings, bulk: true do |t|
      t.change_null :tag_id, true
      t.change_null :taggable_id, true
      t.change_null :taggable_type, true
    end
  end
end
