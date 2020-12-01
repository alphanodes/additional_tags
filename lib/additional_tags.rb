require 'additional_tags/version'

module AdditionalTags
  TAG_TABLE_NAME = 'additional_tags'.freeze
  TAGGING_TABLE_NAME = 'additional_taggings'.freeze

  class << self
    def setup
      raise 'Please install additionals plugin (https://github.com/alphanodes/additionals)' unless Redmine::Plugin.installed? 'additionals'

      Additionals.incompatible_plugins(%w[redmine_tags
                                          redmine_tagging
                                          redmineup_tags], 'additional_tags')

      # Patches
      AutoCompletesController.include AdditionalTags::Patches::AutoCompletesControllerPatch
      CalendarsController.include AdditionalTags::Patches::CalendarsControllerPatch
      DashboardsController.include AdditionalTags::Patches::DashboardsControllerPatch
      DashboardAsyncBlocksController.include AdditionalTags::Patches::DashboardAsyncBlocksControllerPatch
      GanttsController.include AdditionalTags::Patches::GanttsControllerPatch
      Issue.include AdditionalTags::Patches::IssuePatch
      IssuesController.include AdditionalTags::Patches::IssuesControllerPatch
      ImportsController.include AdditionalTags::Patches::ImportsControllerPatch
      Redmine::Export::PDF::IssuesPdfHelper.include AdditionalTags::Patches::IssuesPdfHelperPatch
      QueriesHelper.include AdditionalTags::Patches::QueriesHelperPatch
      ReportsController.include AdditionalTags::Patches::ReportsControllerPatch
      SettingsController.include AdditionalTags::Patches::SettingsControllerPatch
      Redmine::Helpers::TimeReport.include AdditionalTags::Patches::TimeReportPatch
      TimeEntry.include AdditionalTags::Patches::TimeEntryPatch
      TimelogController.include AdditionalTags::Patches::TimelogControllerPatch
      WikiController.include AdditionalTags::Patches::WikiControllerPatch
      WikiPage.include AdditionalTags::Patches::WikiPagePatch

      # because of this bug: https://www.redmine.org/issues/33290
      if Additionals.redmine_database_ready? TAG_TABLE_NAME
        IssueQuery.include AdditionalTags::Patches::IssueQueryPatch
        TimeEntryQuery.include AdditionalTags::Patches::TimeEntryQueryPatch
      end

      if Redmine::Plugin.installed? 'redmine_agile'
        AgileQuery.include AdditionalTags::Patches::AgileQueryPatch
        AgileVersionsQuery.include(AdditionalTags::Patches::AgileVersionsQueryPatch) if AGILE_VERSION_TYPE == 'PRO version'
      end

      # Hooks
      require_dependency 'additional_tags/hooks'
    end

    # support with default setting as fall back
    def setting(value)
      if settings.key? value
        settings[value]
      else
        Additionals.load_settings('additional_tags')[value]
      end
    end

    def setting?(value)
      Additionals.true? settings[value]
    end

    def show_sidebar_tags?
      setting(:tags_sidebar).present? && setting(:tags_sidebar) != 'none'
    end

    def all_type_tags(klass, options = {})
      ActsAsTaggableOn::Tag.where({})
                           .joins(tag_for_joins(klass, options))
                           .distinct
                           .order("#{TAG_TABLE_NAME}.name")
    end

    def available_tags(klass, options = {})
      scope = ActsAsTaggableOn::Tag.where({})
      scope = scope.where("#{Project.table_name}.id = ?", options[:project]) if options[:project]
      if options[:permission]
        scope = scope.where(tag_access(options[:permission]))
      elsif options[:visible_condition]
        scope = scope.where(klass.visible_condition(User.current))
      end
      scope = scope.where("LOWER(#{TAG_TABLE_NAME}.name) LIKE ?", "%#{options[:name_like].downcase}%") if options[:name_like]
      scope = scope.where("#{TAG_TABLE_NAME}.name=?", options[:name]) if options[:name]
      scope = scope.where("#{TAGGING_TABLE_NAME}.taggable_id!=?", options[:exclude_id]) if options[:exclude_id]
      scope = scope.where(options[:where_field] => options[:where_value]) if options[:where_field].present? && options[:where_value]

      columns = ["#{TAG_TABLE_NAME}.*",
                 "COUNT(DISTINCT #{TAGGING_TABLE_NAME}.taggable_id) AS count"]

      order = options[:order] == 'DESC' ? 'DESC' : 'ASC'
      columns << "MIN(#{TAGGING_TABLE_NAME}.created_at) AS created_at" if options[:sort_by] == 'created_at'
      order_column = options[:sort_by] || 'name'

      scope.select(columns.join(', '))
           .joins(tag_for_joins(klass, options))
           .group("#{TAG_TABLE_NAME}.id, #{TAG_TABLE_NAME}.name").having('COUNT(*) > 0')
           .order(Arel.sql("#{TAG_TABLE_NAME}.#{ActiveRecord::Base.connection.quote_column_name order_column} #{order}"))
    end

    def remove_unused_tags
      ActsAsTaggableOn::Tag.where.not(id: ActsAsTaggableOn::Tagging.select(:tag_id).distinct)
                           .each(&:destroy)
    end

    def sql_for_tags_field(klass, operator, value)
      compare   = operator.eql?('=') ? 'IN' : 'NOT IN'
      ids_list  = klass.tagged_with(value).map(&:id).push(0).join(',')
      "(#{klass.table_name}.id #{compare} (#{ids_list})) "
    end

    def tag_to_joins(klass)
      table_name = klass.table_name

      joins = ["JOIN #{TAGGING_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.taggable_id = #{table_name}.id" \
               " AND #{TAGGING_TABLE_NAME}.taggable_type = '#{klass}'"]
      joins << "JOIN #{TAG_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.tag_id = #{TAG_TABLE_NAME}.id"

      joins
    end

    # sort tag_list alphabetically with special characters support
    def sort_tag_list(tag_list)
      tag_list.to_a.sort! do |a, b|
        ActiveSupport::Inflector.transliterate(a.name.downcase) <=> ActiveSupport::Inflector.transliterate(b.name.downcase)
      end
    end

    # sort tags alphabetically with special characters support
    def sort_tags(tags)
      tags.sort! do |a, b|
        ActiveSupport::Inflector.transliterate(a.downcase) <=> ActiveSupport::Inflector.transliterate(b.downcase)
      end
    end

    private

    def settings
      Setting[:plugin_additional_tags]
    end

    def tag_access(permission)
      projects_allowed = if permission.nil?
                           Project.visible.ids
                         else
                           Project.where(Project.allowed_to_condition(User.current, permission)).ids
                         end

      if projects_allowed.present?
        "#{Project.table_name}.id IN (#{projects_allowed.join ','})" unless projects_allowed.empty?
      else
        '1=0'
      end
    end

    def tag_for_joins(klass, options = {})
      table_name = klass.table_name

      joins = ["JOIN #{TAGGING_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.tag_id = #{TAG_TABLE_NAME}.id"]
      joins << "JOIN #{table_name} " \
               "ON #{table_name}.id = #{TAGGING_TABLE_NAME}.taggable_id AND #{TAGGING_TABLE_NAME}.taggable_type = '#{klass}'"

      if options[:project_join]
        joins << options[:project_join]
      elsif options[:project] || !options[:without_projects]
        joins << "JOIN #{Project.table_name} ON #{table_name}.project_id = #{Project.table_name}.id"
      end

      joins
    end
  end

  # Run the classic redmine plugin initializer after rails boot
  class Plugin < ::Rails::Engine
    require 'acts-as-taggable-on'

    ActsAsTaggableOn.tags_table = TAG_TABLE_NAME
    ActsAsTaggableOn.taggings_table = TAGGING_TABLE_NAME

    config.after_initialize do
      # engine_name could be used (additional_tags_plugin), but can
      # create some side effencts
      plugin_id = 'additional_tags'

      # if plugin is already in plugins directory, use this and leave here
      next if Redmine::Plugin.installed? plugin_id

      # gem is used as redmine plugin
      require File.expand_path '../init', __dir__
      AdditionalTags.setup
      Additionals::Gemify.install_assets plugin_id
      Additionals::Gemify.create_plugin_hint plugin_id
    end
  end
end
