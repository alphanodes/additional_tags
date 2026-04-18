# frozen_string_literal: true

class RemoveContextFromAdditionalTaggings < ActiveRecord::Migration[7.2]
  def up
    return unless column_exists? :additional_taggings, :context

    # MySQL requires dropping foreign key before dropping its supporting index
    remove_foreign_key :additional_taggings, :additional_tags if foreign_key_exists? :additional_taggings, :additional_tags

    remove_index :additional_taggings, name: 'ataggings_idx', if_exists: true
    remove_index :additional_taggings, name: 'ataggings_taggable_context_idx', if_exists: true
    remove_index :additional_taggings, name: 'ataggings_idy', if_exists: true
    remove_index :additional_taggings, column: :context, if_exists: true

    remove_column :additional_taggings, :context

    unless index_exists? :additional_taggings, %i[tag_id taggable_id taggable_type tagger_id tagger_type], name: 'ataggings_idx'
      add_index :additional_taggings,
                %i[tag_id taggable_id taggable_type tagger_id tagger_type],
                unique: true, name: 'ataggings_idx'
    end

    unless index_exists? :additional_taggings, %i[taggable_id taggable_type], name: 'ataggings_taggable_idx'
      add_index :additional_taggings,
                %i[taggable_id taggable_type],
                name: 'ataggings_taggable_idx'
    end

    unless index_exists? :additional_taggings, %i[taggable_id taggable_type tagger_id], name: 'ataggings_idy'
      add_index :additional_taggings,
                %i[taggable_id taggable_type tagger_id],
                name: 'ataggings_idy'
    end

    add_foreign_key :additional_taggings, :additional_tags, column: :tag_id unless foreign_key_exists? :additional_taggings,
                                                                                                       :additional_tags
  end

  def down
    # context column is no longer used - nothing to restore
  end
end
