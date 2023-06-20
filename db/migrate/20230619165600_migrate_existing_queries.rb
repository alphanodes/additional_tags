# frozen_string_literal: true

class MigrateExistingQueries < ActiveRecord::Migration[5.2]
  def up
    Query.subclasses.each do |q|
      q.all.each do |query|
        query.filters['tags'] = query.filters.delete('issue_tags') if query.filters.key?('issue_tags')
        query.column_names.map! { |x| x == :tags_relations ? :tags : x } if query.column_names.is_a?(Array) && query.column_names.include?(:tags_relations)
        query.save
      end
    end
  end

  def down
    # to nothing
  end
end
