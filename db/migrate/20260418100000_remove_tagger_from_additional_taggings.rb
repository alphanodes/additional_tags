# frozen_string_literal: true

class RemoveTaggerFromAdditionalTaggings < ActiveRecord::Migration[7.2]
  def up
    return unless column_exists? :additional_taggings, :tagger_id

    # MySQL requires dropping foreign key before dropping its supporting index
    remove_foreign_key :additional_taggings, :additional_tags if foreign_key_exists? :additional_taggings, :additional_tags

    remove_index :additional_taggings, name: 'ataggings_idx', if_exists: true
    remove_index :additional_taggings, name: 'ataggings_idy', if_exists: true
    remove_index :additional_taggings, name: 'index_additional_taggings_on_tagger_id_and_tagger_type', if_exists: true
    remove_index :additional_taggings, name: 'index_additional_taggings_on_tagger_type_and_tagger_id', if_exists: true
    # duplicate of ataggings_taggable_idx
    remove_index :additional_taggings, name: 'index_additional_taggings_on_taggable_type_and_taggable_id', if_exists: true

    change_table :additional_taggings, bulk: true do |t|
      t.remove :tagger_id
      t.remove :tagger_type
    end

    # Defensive: brownfield rows with NULL key columns make the unique index
    # break under MariaDB 11.x (NULLs are treated as duplicates there).
    execute 'DELETE FROM additional_taggings ' \
            'WHERE tag_id IS NULL OR taggable_id IS NULL ' \
            "OR taggable_type IS NULL OR taggable_type = ''"

    # Brownfield data: rows that were distinct only by tagger_id/tagger_type now
    # collide with the upcoming unique index on (tag_id, taggable_id,
    # taggable_type). Keep the row with the lowest id per group, drop the rest.
    execute deduplicate_taggings_sql

    unless index_exists? :additional_taggings, %i[tag_id taggable_id taggable_type], name: 'ataggings_idx'
      add_index :additional_taggings,
                %i[tag_id taggable_id taggable_type],
                unique: true, name: 'ataggings_idx'
    end

    add_foreign_key :additional_taggings, :additional_tags, column: :tag_id unless foreign_key_exists? :additional_taggings,
                                                                                                       :additional_tags
  end

  def down
    # tagger columns are no longer used - nothing to restore
  end

  private

  def deduplicate_taggings_sql
    if Redmine::Database.postgresql?
      <<~SQL.squish
        DELETE FROM additional_taggings t1
        USING additional_taggings t2
        WHERE t1.tag_id = t2.tag_id
          AND t1.taggable_id = t2.taggable_id
          AND t1.taggable_type = t2.taggable_type
          AND t1.id > t2.id
      SQL
    else
      <<~SQL.squish
        DELETE t1 FROM additional_taggings t1
        INNER JOIN additional_taggings t2
          ON t1.tag_id = t2.tag_id
         AND t1.taggable_id = t2.taggable_id
         AND t1.taggable_type = t2.taggable_type
         AND t1.id > t2.id
      SQL
    end
  end
end
