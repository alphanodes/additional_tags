# frozen_string_literal: true

class RemovedDuplicatedIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :additional_taggings, name: 'index_additional_taggings_on_taggable_type', column: :taggable_type
  end
end
