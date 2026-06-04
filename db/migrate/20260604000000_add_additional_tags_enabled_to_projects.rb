# db/migrate/20260604000000_add_additional_tags_enabled_to_projects.rb
class AddAdditionalTagsEnabledToProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :additional_tags_enabled, :boolean, default: true
  end
end