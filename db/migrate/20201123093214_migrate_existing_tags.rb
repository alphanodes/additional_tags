# frozen_string_literal: true

class MigrateExistingTags < ActiveRecord::Migration[5.2]
  def up
    return unless table_exists?(MigrateTag.table_name) && table_exists?(MigrateTagging.table_name)

    excluded_taggable_types = %w[Question Contact DriveEntry]

    MigrateTag.find_each do |old_tag|
      AdditionalTagging.transaction do
        tag = AdditionalTag.find_by name: old_tag.name
        cnt = 0
        old_tag.migrate_taggings.each do |tagging|
          next if excluded_taggable_types.include? tagging.taggable_type

          tag = AdditionalTag.create! name: old_tag.name if cnt.zero? && tag.nil?

          # old data can include dups
          next if AdditionalTagging.exists?(tag_id: tag.id,
                                            taggable_id: tagging.taggable_id,
                                            taggable_type: tagging.taggable_type)

          AdditionalTagging.create!(tag_id: tag.id,
                                    taggable_id: tagging.taggable_id,
                                    taggable_type: tagging.taggable_type,
                                    created_at: tagging.created_at)
          cnt += 1
        end

        AdditionalTag.reset_counters tag.id, :taggings unless tag.nil?
      end
    end
  end

  def down
    # to nothing
  end
end
