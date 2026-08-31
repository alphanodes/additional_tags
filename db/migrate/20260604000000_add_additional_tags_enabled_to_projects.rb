class AddAdditionalTagsEnabledToProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :additional_tags_enabled, :boolean, default: true, null: false
  end
end
