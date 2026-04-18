# frozen_string_literal: true

class FixTagsCollation < ActiveRecord::Migration[7.2]
  def up
    return unless Redmine::Database.mysql?

    table = AdditionalTag.table_name
    result = ActiveRecord::Base.connection.select_one(
      'SELECT COLLATION_NAME FROM information_schema.COLUMNS ' \
      "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '#{table}' AND COLUMN_NAME = 'name'"
    )
    return unless result && result['COLLATION_NAME']&.end_with?('_bin')

    execute "ALTER TABLE #{table} MODIFY name varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
  end

  def down
    # intentionally left empty - reverting to _bin would break case-insensitive searches
  end
end
