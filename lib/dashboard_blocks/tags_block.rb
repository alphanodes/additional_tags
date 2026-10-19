# frozen_string_literal: true

module DashboardBlocks
  # The tags of an entity: how many there are, how many entries carry one and
  # as table of values the entries per tag and status, linked to the list. A
  # subclass names the entity, its statuses and its list; the partial
  # dashboards/blocks/tags shows it.
  class TagsBlock < Base
    abstract!

    Summary = Data.define :tags, :count, :columns, :rows
    Row = Data.define :tag, :cells, :total
    # A value of a status, linked to the entries of the tag in that status
    Cell = Data.define :count, :status_id

    def data
      @data ||= begin
        tags = AdditionalTag.sort_for_list available_tags.to_a
        counts = AdditionalTag.entity_group_by scope: count_scope, tags:, statuses:, **group_options
        rows = tags.map { |tag| summary_row tag, counts[tag.name] }
        Summary.new tags:, count: tags.any? ? entities_count(rows) : 0, columns: summary_columns, rows:
      end
    end

    def export_data
      { count: data.count,
        columns: [I18n.t(:field_name), *data.columns],
        rows: data.rows.map { |row| [row.tag.name, *row.cells.map(&:count), row.total] } }
    end

    # Options of additional_tag_link for the entries with a tag, of a status if given
    def tag_link_options(status_id = nil)
      { tag_action: 'index', tag_controller:, filter: tag_filter(status_id) }
    end

    # Parameters of the list of all entries with a tag, nil without such a list
    def totals_params
      raise NotImplementedError
    end

    def entities_label
      raise NotImplementedError
    end

    private

    def available_tags
      raise NotImplementedError
    end

    # Entries to count per tag, by status if the entity has statuses
    def count_scope
      raise NotImplementedError
    end

    def tag_controller
      raise NotImplementedError
    end

    # Query of the list of the entries, which counts the entries with a tag
    def query_class
      raise NotImplementedError
    end

    def count_method
      :query_count
    end

    # Filter of the list for the status
    def status_field
      :status_id
    end

    # Statuses as id and key, nil for an entity without statuses
    def statuses
      nil
    end

    def status_label(_status_id, _key)
      raise NotImplementedError
    end

    # The status the settings restrict the block to, nil for all statuses
    def only_status
      nil
    end

    def only_one_status?
      !only_status.nil?
    end

    # The count of an entry of entity_group_by for the only status
    def one_status_key
      statuses[only_status]
    end

    # Further options of AdditionalTag.entity_group_by
    def group_options
      {}
    end

    def entities_count(_rows)
      query = query_class.new project:, name: '_'
      query.add_filter 'tags', '*'
      # The default filter of the list restricts it to the only status
      query.filters.delete status_field.to_s unless only_one_status?
      query.public_send count_method
    end

    def tag_filter(status_id)
      status_id = only_status if status_id.nil?
      { field: status_field, operator: '=', value: [status_id.to_s] } unless status_id.nil?
    end

    def by_status?
      statuses.present? && !only_one_status?
    end

    def summary_columns
      return [I18n.t(:label_quantity)] unless by_status?

      statuses.map { |status_id, key| status_label status_id, key } + [I18n.t(:label_total)]
    end

    def summary_row(tag, counts)
      cells = by_status? ? counts[:groups].map { |group| Cell.new group[:count], group[:id] } : []
      Row.new tag, cells, only_one_status? ? counts[one_status_key] : counts[:total]
    end
  end
end
