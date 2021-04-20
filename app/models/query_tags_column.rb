# frozen_string_literal: true

class QueryTagsColumn < QueryRelationsColumn
  def initialize(name = :tags, **options)
    super name, **options
  end
end
