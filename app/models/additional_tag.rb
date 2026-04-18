# frozen_string_literal: true

class AdditionalTag < ApplicationRecord
  GROUP_SEP = ':'
  SCOPE_SEP = '::'

  attr_accessor :disable_grouping, :color_theme, :bg_color

  has_many :taggings,
           dependent: :destroy,
           class_name: 'AdditionalTagging',
           foreign_key: :tag_id,
           inverse_of: :tag

  validates :name, presence: true,
                   uniqueness: { case_sensitive: true },
                   length: { maximum: 255 }

  scope :named, ->(name) { where "LOWER(#{table_name}.name) = ?", name.to_s.downcase }
  scope :named_any, lambda { |list|
    list = Array(list).map { |t| t.to_s.downcase }
    where "LOWER(#{table_name}.name) IN (?)", list
  }
  scope :most_used, ->(limit = 20) { order(taggings_count: :desc).limit limit }

  class << self
    def find_or_create_all_with_like_by_name(*list)
      list = list.flatten
      list.compact!
      list.map!(&:strip)
      list.compact_blank!
      list.uniq!
      return [] if list.empty?

      existing = named_any(list).to_a
      list.map do |name|
        existing.detect { |t| t.name.casecmp(name).zero? } ||
          create!(name: name)
      rescue ActiveRecord::RecordNotUnique
        named(name).first || raise
      end
    end

    def mutually_exclusive_tags?(tag_list)
      return true if tag_list.blank?

      tags = tag_list.select { |t| t.include? SCOPE_SEP }
      return true if tags.blank?

      groups = tags.map { |t| new(name: t).group_name }
      groups == groups.uniq
    end

    # Returns project IDs where user has the given tag permission as SQL condition string.
    # Used by available_tags and entity queries to filter by tag visibility.
    #
    # user - the User to check permissions for
    # options - :permission (default :view_issue_tags), :skip_pre_condition (default true)
    def visible_condition(user, **options)
      permission = options[:permission] || :view_issue_tags
      skip_pre_condition = options[:skip_pre_condition] || true

      tag_access permission, user, skip_pre_condition:
    end

    # Returns available tags for a given model class, filtered by project, permissions and name.
    # Used by all taggable models (Issue, WikiPage, DbEntry, Password, etc.) in their `available_tags` class method.
    #
    # klass - the taggable model class (e.g. Issue, WikiPage)
    # options - :project, :permission, :name_like, :name, :sort_by, :order, :exclude_id,
    #           :user, :visible_condition, :skip_pre_condition, :where_field, :where_value,
    #           :project_join, :without_projects
    def available_tags(klass, **options)
      user = options[:user].presence || User.current

      scope = where({})
      if options[:project]
        scope = if Setting.display_subprojects_issues?
                  scope.where subproject_sql(options[:project])
                else
                  scope.where projects: { id: options[:project] }
                end
      end

      if options[:permission]
        scope = scope.where tag_access(options[:permission], user, skip_pre_condition: options[:skip_pre_condition])
      elsif options[:visible_condition]
        scope = scope.where klass.visible_condition(user)
      end

      # @TODO: this should be activated and replace next line
      #        Additionals::EntityMethodsGlobal should be included for this
      #
      # if options[:name_like]
      #   scope = scope.like_with_wildcard columns: "#{table_name}.name",
      #                                    value: options[:name_like],
      #                                    wildcard: :both
      # end
      if options[:name_like]
        scope = scope.where Redmine::Database.like("#{table_name}.name", '?'),
                            "%#{options[:name_like]}%"
      end
      scope = scope.where "#{table_name}.name=?", options[:name] if options[:name]
      scope = scope.where "#{AdditionalTagging.table_name}.taggable_id!=?", options[:exclude_id] if options[:exclude_id]
      scope = scope.where options[:where_field] => options[:where_value] if options[:where_field].present? && options[:where_value]

      scope.select(table_columns(options[:sort_by]))
           .joins(tag_for_joins(klass, **options.slice(:project_join, :project, :without_projects)))
           .group("#{table_name}.id, #{table_name}.name," \
                  " #{table_name}.taggings_count")
           .having('COUNT(*) > 0')
           .order(build_order_sql(options[:sort_by], options[:order]))
    end

    # Returns all distinct tags for a specific taggable type, ordered by name.
    #
    # klass - the taggable model class (e.g. Issue, WikiPage)
    # without_projects - if true, skip the projects JOIN (default false)
    def all_type_tags(klass, without_projects: false)
      joins(tag_for_joins(klass, without_projects:))
        .distinct
        .order(:name)
    end

    # Returns SQL JOIN clauses to join a taggable model's table through taggings to tags.
    # Used by other plugins (e.g. redmine_reporting) for tag-based queries on issues.
    #
    # klass - the taggable model class
    def tag_to_joins(klass)
      klass_table_name = klass.table_name

      joins = ["JOIN #{AdditionalTagging.table_name} ON #{AdditionalTagging.table_name}.taggable_id = #{klass_table_name}.id" \
               " AND #{AdditionalTagging.table_name}.taggable_type = '#{klass}'"]
      joins << "JOIN #{table_name} ON #{AdditionalTagging.table_name}.tag_id = #{table_name}.id"

      joins
    end

    # Deletes all tags that have no associated taggings.
    def remove_unused_tags
      where.missing(:taggings)
           .each(&:destroy)
    end

    # Merges multiple tags into one, reassigning all taggings and removing duplicates.
    # If the target tag does not exist, it is created.
    #
    # tag_name - the name of the target tag
    # tags_to_merge - array of AdditionalTag records to merge into the target
    def merge(tag_name, tags_to_merge)
      return if tag_name.blank? || tags_to_merge.none?

      AdditionalTagging.transaction do
        tag = find_by(name: tag_name) || create(name: tag_name)
        # Update old tagging with new tag
        AdditionalTagging.where(tag_id: tags_to_merge.map(&:id))
                         .update_all tag_id: tag.id
        # remove old (merged) tags
        tags_to_merge.reject { |t| t.id == tag.id }.each(&:destroy)
        # remove duplicate taggings
        dup_scope = AdditionalTagging.where tag_id: tag.id
        valid_ids = dup_scope.group(:tag_id, :taggable_id, :taggable_type, :tagger_id, :tagger_type)
                             .pluck(Arel.sql('MIN(id)'))
        dup_scope.where.not(id: valid_ids).destroy_all if valid_ids.any?
        # recalc count for new tag
        reset_counters tag.id, :taggings
      end
    end

    # Sorts an array of tag name strings alphabetically, using transliteration for special characters.
    #
    # tags - array of tag name strings (sorted in place)
    def sort_tags(tags)
      tags.sort! do |a, b|
        ActiveSupport::Inflector.transliterate(a.downcase) <=> ActiveSupport::Inflector.transliterate(b.downcase)
      end
    end

    # Sorts a tag_list (collection of tag objects) alphabetically by name with transliteration.
    #
    # tag_list - a tag list (e.g. from a taggable record's `tag_list`)
    def sort_tag_list(tag_list)
      tag_list.to_a.sort! do |a, b|
        ActiveSupport::Inflector.transliterate(a.name.downcase) <=> ActiveSupport::Inflector.transliterate(b.name.downcase)
      end
    end

    # Extracts unique tags from a collection of tagged entries.
    #
    # entries - a single entry or array of entries that respond to `tags`
    def build_relation_tags(entries)
      entries = Array entries
      return [] if entries.none?

      tags = entries.map(&:tags)
      tags.flatten!

      tags.uniq
    end

    # Groups entities by tag and status for dashboard widgets.
    # Returns a hash keyed by tag name with totals and per-status counts.
    #
    # scope - pre-computed count data (hash)
    # tags - array of AdditionalTag records
    # statuses - array of [group_id, group_name] pairs (optional)
    # sub_groups - array of group_ids to sum into total_sub_groups (optional)
    # group_id_is_bool - if true, treat group_id as boolean (default false)
    def entity_group_by(scope:, tags:, statuses: nil, sub_groups: nil, group_id_is_bool: false)
      counts = {}
      tags.each do |tag|
        values = { tag:, total: 0, total_sub_groups: 0, groups: [] }

        if statuses
          statuses.each do |status|
            group_id = status.first
            group = status.second
            values[group] = status_for_tag_value(scope:,
                                                 tag_id: tag.id,
                                                 group_id:,
                                                 group_id_is_bool:)
            values[:groups] << { id: group_id, group:, count: values[group] }
            values[:total] += values[group]
            values[:total_sub_groups] += values[group] if sub_groups&.include? group_id
          end
        else
          values[:total] += status_for_tag_value scope:, tag_id: tag.id
        end

        values[:total_without_sub_groups] = values[:total] - values[:total_sub_groups]

        counts[tag.name] = values
      end

      counts
    end

    # Returns SQL condition for project hierarchy (subprojects) using lft/rgt tree values.
    #
    # project - a Project record
    def subproject_sql(project)
      "#{Project.table_name}.lft >= #{project.lft} " \
        "AND #{Project.table_name}.rgt <= #{project.rgt}"
    end

    private

    def table_columns(sort_by)
      columns = ["#{table_name}.id",
                 "#{table_name}.name",
                 "#{table_name}.taggings_count",
                 "COUNT(DISTINCT #{AdditionalTagging.table_name}.taggable_id) AS count"]

      columns << "MIN(#{AdditionalTagging.table_name}.created_at) AS last_created" if sort_by == 'last_created'
      columns.to_comma_list
    end

    def status_for_tag_value(scope:, tag_id:, group_id: nil, group_id_is_bool: false)
      value = if group_id_is_bool || group_id
                if group_id_is_bool
                  if group_id
                    scope[[1, tag_id]] || scope[[true, tag_id]]
                  else
                    scope[[0, tag_id]] || scope[[false, tag_id]]
                  end
                else
                  scope[[group_id, tag_id]]
                end
              else
                scope[tag_id]
              end

      value || 0
    end

    def build_order_sql(sort_by, order)
      order = order.present? && order == 'DESC' ? 'DESC' : 'ASC'

      sql = case sort_by
            when 'last_created'
              "last_created #{order}, #{table_name}.name ASC"
            when 'count'
              "count #{order}, #{table_name}.name ASC"
            else
              "#{table_name}.name #{order}"
            end

      Arel.sql sql
    end

    def tag_for_joins(klass, project_join: nil, project: nil, without_projects: false)
      klass_table_name = klass.table_name

      joins = ["JOIN #{AdditionalTagging.table_name} ON #{AdditionalTagging.table_name}.tag_id = #{table_name}.id"]
      joins << "JOIN #{klass_table_name}" \
               " ON #{klass_table_name}.id = #{AdditionalTagging.table_name}.taggable_id" \
               " AND #{AdditionalTagging.table_name}.taggable_type = '#{klass}'"

      if project_join
        joins << project_join
      elsif project || !without_projects
        joins << "JOIN #{Project.table_name} ON #{klass_table_name}.project_id = #{Project.table_name}.id"
      end

      joins
    end

    def tag_access(permission, user, skip_pre_condition: false)
      projects_allowed = if permission.nil?
                           Project.visible.ids
                         else
                           Project.where(Project.allowed_to_condition(user, permission, skip_pre_condition:)).ids
                         end

      if projects_allowed.present?
        "#{Project.table_name}.id IN (#{projects_allowed.join ','})" unless projects_allowed.empty?
      else
        Additionals::SQL_NO_RESULT_CONDITION
      end
    end
  end

  def ==(other)
    super || (other.is_a?(self.class) && name == other.name)
  end

  delegate :to_s, to: :name

  def count
    self[:count].to_i
  end

  def name_for_color
    color_name = if scoped? || grouped?
                   "#{group_name}#{sep}"
                 else
                   tag_name
                 end

    if color_theme.present? && color_theme != '0' && color_theme != '1'
      "#{color_name}#{color_theme}"
    else
      color_name
    end
  end

  def tag_bg_color
    @tag_bg_color ||= bg_color || "##{Digest::SHA256.hexdigest(name_for_color)[0..5]}"
  end

  def tag_fg_color
    @tag_fg_color ||= begin
      r = tag_bg_color[1..2].hex
      g = tag_bg_color[3..4].hex
      b = tag_bg_color[5..6].hex
      (r * 299 + g * 587 + b * 114) >= 128_000 ? 'black' : 'white'
    end
  end

  def sep
    scoped? ? SCOPE_SEP : GROUP_SEP
  end

  def tag_name
    scoped? ? group_name : name.to_s
  end

  def labels
    @labels ||= scoped? ? scope_labels : group_labels
  end

  def scope_labels
    @scope_labels ||= name.to_s.split(SCOPE_SEP).map(&:strip)
  end

  def group_labels
    @group_labels ||= name.to_s.split(GROUP_SEP).map(&:strip)
  end

  def group_name
    if labels.length > 2
      labels[0...-1].join sep
    else
      labels.first
    end
  end

  def group_value
    labels.last
  end

  def scoped?
    !disable_grouping && scope_labels.length > 1
  end

  def grouped?
    !disable_grouping && group_labels.length > 1
  end
end
