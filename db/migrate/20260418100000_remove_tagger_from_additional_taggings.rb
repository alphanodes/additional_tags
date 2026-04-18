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
end
