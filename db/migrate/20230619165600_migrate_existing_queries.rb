# frozen_string_literal: true

class MigrateExistingQueries < ActiveRecord::Migration[5.2]
  def up
    Query.all.each do |query|
      if query.filters.has_key?("issue_tags")
        query.filters["tags"] = query.filters.delete("issue_tags")
      end

      if  query.column_names.is_a?(Array) && query.column_names.include?(:tags_relations)
        query.column_names.map! { |x| x == :tags_relations ? :tags : x }
      end
      query.save
    end
  end

  def down
    # to nothing
  end
end
