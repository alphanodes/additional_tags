# frozen_string_literal: true

module AdditionalTags
  class Tags
    class << self
      def visible_condition(user, **options)
        permission = options[:permission] || :view_issue_tags
        skip_pre_condition = options[:skip_pre_condition] || true

        tag_access permission, user, skip_pre_condition: skip_pre_condition
      end

      def available_tags(klass, **options)
        user = options[:user].presence || User.current

        scope = ActsAsTaggableOn::Tag.where({})
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
        #   scope = scope.like_with_wildcard columns: "#{TAG_TABLE_NAME}.name",
        #                                    value: options[:name_like],
        #                                    wildcard: :both
        # end
        scope = scope.where "LOWER(#{TAG_TABLE_NAME}.name) LIKE ?", "%#{options[:name_like].downcase}%" if options[:name_like]
        scope = scope.where "#{TAG_TABLE_NAME}.name=?", options[:name] if options[:name]
        scope = scope.where "#{TAGGING_TABLE_NAME}.taggable_id!=?", options[:exclude_id] if options[:exclude_id]
        scope = scope.where options[:where_field] => options[:where_value] if options[:where_field].present? && options[:where_value]

        scope.select(table_columns(options[:sort_by]))
             .joins(tag_for_joins(klass, **options.slice(:project_join, :project, :without_projects)))
             .group("#{TAG_TABLE_NAME}.id, #{TAG_TABLE_NAME}.name, #{TAG_TABLE_NAME}.taggings_count").having('COUNT(*) > 0')
             .order(build_order_sql(options[:sort_by], options[:order]))
      end

      def all_type_tags(klass, without_projects: false)
        ActsAsTaggableOn::Tag.joins(tag_for_joins(klass, without_projects: without_projects))
                             .distinct
                             .order(:name)
      end

      def tag_to_joins(klass)
        table_name = klass.table_name

        joins = ["JOIN #{TAGGING_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.taggable_id = #{table_name}.id" \
                 " AND #{TAGGING_TABLE_NAME}.taggable_type = '#{klass}'"]
        joins << "JOIN #{TAG_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.tag_id = #{TAG_TABLE_NAME}.id"

        joins
      end

      def remove_unused_tags
        ActsAsTaggableOn::Tag.where.missing(:taggings)
                             .each(&:destroy)
      end

      def merge(tag_name, tags_to_merge)
        return if tag_name.blank? || tags_to_merge.none?

        ActsAsTaggableOn::Tagging.transaction do
          tag = ActsAsTaggableOn::Tag.find_by(name: tag_name) || ActsAsTaggableOn::Tag.create(name: tag_name)
          # Update old tagging with new tag
          ActsAsTaggableOn::Tagging.where(tag_id: tags_to_merge.map(&:id)).update_all tag_id: tag.id
          # remove old (merged) tags
          tags_to_merge.reject { |t| t.id == tag.id }.each(&:destroy)
          # remove duplicate taggings
          dup_scope = ActsAsTaggableOn::Tagging.where tag_id: tag.id
          valid_ids = dup_scope.group(:tag_id, :taggable_id, :taggable_type, :tagger_id, :tagger_type, :context)
                               .pluck(Arel.sql('MIN(id)'))
          dup_scope.where.not(id: valid_ids).destroy_all if valid_ids.any?
          # recalc count for new tag
          ActsAsTaggableOn::Tag.reset_counters tag.id, :taggings
        end
      end

      # sort tags alphabetically with special characters support
      def sort_tags(tags)
        tags.sort! do |a, b|
          ActiveSupport::Inflector.transliterate(a.downcase) <=> ActiveSupport::Inflector.transliterate(b.downcase)
        end
      end

      # sort tag_list alphabetically with special characters support
      def sort_tag_list(tag_list)
        tag_list.to_a.sort! do |a, b|
          ActiveSupport::Inflector.transliterate(a.name.downcase) <=> ActiveSupport::Inflector.transliterate(b.name.downcase)
        end
      end

      def build_relation_tags(entries)
        entries = Array entries
        return [] if entries.none?

        tags = entries.map(&:tags)
        tags.flatten!

        tags.uniq
      end

      def entity_group_by(scope:, tags:, statuses: nil, sub_groups: nil, group_id_is_bool: false)
        counts = {}
        tags.each do |tag|
          values = { tag: tag, total: 0, total_sub_groups: 0, groups: [] }

          if statuses
            statuses.each do |status|
              group_id = status.first
              group = status.second
              values[group] = status_for_tag_value scope: scope,
                                                   tag_id: tag.id,
                                                   group_id: group_id,
                                                   group_id_is_bool: group_id_is_bool
              values[:groups] << { id: group_id, group: group, count: values[group] }
              values[:total] += values[group]
              values[:total_sub_groups] += values[group] if sub_groups&.include? group_id
            end
          else
            values[:total] += status_for_tag_value scope: scope, tag_id: tag.id
          end

          values[:total_without_sub_groups] = values[:total] - values[:total_sub_groups]

          counts[tag.name] = values
        end

        counts
      end

      def subproject_sql(project)
        "#{Project.table_name}.lft >= #{project.lft} " \
          "AND #{Project.table_name}.rgt <= #{project.rgt}"
      end

      private

      def table_columns(sort_by)
        columns = ["#{TAG_TABLE_NAME}.id",
                   "#{TAG_TABLE_NAME}.name",
                   "#{TAG_TABLE_NAME}.taggings_count",
                   "COUNT(DISTINCT #{TAGGING_TABLE_NAME}.taggable_id) AS count"]

        columns << "MIN(#{TAGGING_TABLE_NAME}.created_at) AS last_created" if sort_by == 'last_created'
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
                "last_created #{order}, #{TAG_TABLE_NAME}.name ASC"
              when 'count'
                "count #{order}, #{TAG_TABLE_NAME}.name ASC"
              else
                "#{TAG_TABLE_NAME}.name #{order}"
              end

        Arel.sql sql
      end

      def tag_for_joins(klass, project_join: nil, project: nil, without_projects: false)
        table_name = klass.table_name

        joins = ["JOIN #{TAGGING_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.tag_id = #{TAG_TABLE_NAME}.id"]
        joins << "JOIN #{table_name} " \
                 "ON #{table_name}.id = #{TAGGING_TABLE_NAME}.taggable_id AND #{TAGGING_TABLE_NAME}.taggable_type = '#{klass}'"

        if project_join
          joins << project_join
        elsif project || !without_projects
          joins << "JOIN #{Project.table_name} ON #{table_name}.project_id = #{Project.table_name}.id"
        end

        joins
      end

      def tag_access(permission, user, skip_pre_condition: false)
        projects_allowed = if permission.nil?
                             Project.visible.ids
                           else
                             Project.where(Project.allowed_to_condition(user, permission, skip_pre_condition: skip_pre_condition)).ids
                           end

        if projects_allowed.present?
          "#{Project.table_name}.id IN (#{projects_allowed.join ','})" unless projects_allowed.empty?
        else
          AdditionalsQuery::NO_RESULT_CONDITION
        end
      end
    end
  end
end
