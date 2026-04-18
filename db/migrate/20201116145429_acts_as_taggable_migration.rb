# frozen_string_literal: true

class ActsAsTaggableMigration < ActiveRecord::Migration[5.2]
  def up
    unless table_exists? AdditionalTag.table_name
      create_table AdditionalTag.table_name do |t|
        t.string :name, index: { unique: true }
        t.integer :taggings_count, default: 0
        t.timestamps
      end
    end

    unless table_exists? AdditionalTagging.table_name
      create_table AdditionalTagging.table_name do |t|
        t.references :tag, foreign_key: { to_table: AdditionalTag.table_name }, index: false

        # You should make sure that the column created is
        # long enough to store the required class names.
        t.references :taggable, polymorphic: true
        t.references :tagger, polymorphic: true

        # Limit is created to prevent MySQL error on index
        # length for MyISAM table type: http://bit.ly/vgW2Ql
        t.string :context, limit: 128

        t.datetime :created_at

        t.index %i[tag_id taggable_id taggable_type context tagger_id tagger_type], unique: true, name: 'ataggings_idx'
        t.index %i[taggable_id taggable_type context], name: 'ataggings_taggable_context_idx'
        t.index :taggable_type
        t.index :context
        t.index %i[tagger_id tagger_type]
        t.index %i[taggable_id taggable_type tagger_id context], name: 'ataggings_idy'
      end
    end

    return unless AdditionalTags::Utils.using_mysql?

    execute "ALTER TABLE #{AdditionalTag.table_name} MODIFY name varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
  end

  def down
    drop_table AdditionalTagging.table_name, if_exists: true
    drop_table AdditionalTag.table_name, if_exists: true
  end
end
