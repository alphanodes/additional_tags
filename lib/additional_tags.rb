# frozen_string_literal: true

require 'additional_tags/tags'

module AdditionalTags
  TAG_TABLE_NAME = 'additional_tags'
  TAGGING_TABLE_NAME = 'additional_taggings'

  class << self
    def setup
      # TODO: this check does not work with Rails 6 at the moment
      # reason: ActiveSupport.on_load(:active_record) is used for setup
      # as temp solution
      if Rails.version < '6.0' && !Redmine::Plugin.installed?('additionals')
        raise 'Please install additionals plugin (https://github.com/alphanodes/additionals)'
      end

      loader = AdditionalsLoader.new plugin_id: 'additional_tags'

      loader.incompatible? %w[redmine_tags
                              redmine_tagging
                              redmineup_tags]

      # Patches
      loader.add_patch %w[AutoCompletesController
                          CalendarsController
                          DashboardsController
                          DashboardAsyncBlocksController
                          GanttsController
                          MyController
                          Issue
                          Journal
                          Query
                          IssuesController
                          ImportsController
                          QueriesHelper
                          ReportsController
                          SettingsController
                          TimeEntry
                          TimelogController
                          WikiController
                          WikiPage]

      loader.add_patch({ target: Redmine::Helpers::TimeReport,
                         patch: 'TimeReport' })

      # because of this bug: https://www.redmine.org/issues/33290
      if AdditionalsLoader.redmine_database_ready? TAG_TABLE_NAME
        loader.add_patch %w[IssueQuery TimeEntryQuery]

        if Redmine::Plugin.installed? 'redmine_agile'
          loader.add_patch %w[AgileQuery AgileBoardsController]
          loader.add_patch %w[AgileVersionsController AgileVersionsQuery] if AGILE_VERSION_TYPE == 'PRO version'
        end
      end

      # Apply patches and helper
      loader.apply!
    end

    # support with default setting as fall back
    def setting(value)
      if settings.key? value
        settings[value]
      else
        AdditionalsLoader.default_settings('additional_tags')[value]
      end
    end

    def setting?(value)
      Additionals.true? settings[value]
    end

    def show_sidebar_tags?
      setting(:tags_sidebar).present? && setting(:tags_sidebar) != 'none'
    end

    private

    def settings
      Setting[:plugin_additional_tags]
    end
  end

  # Run the classic redmine plugin initializer after rails boot
  class Plugin < ::Rails::Engine
    require 'acts-as-taggable-on'

    ActsAsTaggableOn.tags_table = TAG_TABLE_NAME
    ActsAsTaggableOn.taggings_table = TAGGING_TABLE_NAME

    config.after_initialize do
      # engine_name could be used (additional_tags_plugin), but can
      # create some side effects
      plugin_id = 'additional_tags'

      # if plugin is already in plugins directory, use this and leave here
      next if Redmine::Plugin.installed? plugin_id

      if Rails.version > '6.0'
        directory = AdditionalsLoader.plugin_dir plugin_id
        engine_cfg = Rails::Engine::Configuration.new directory.to_s
        engine_cfg.paths.add 'lib', eager_load: true
        engine_cfg.eager_load_paths.each do |dir|
          Rails.autoloaders.main.push_dir dir
        end
      end

      # gem is used as redmine plugin
      require File.expand_path '../init', __dir__
      AdditionalTags.setup if Rails.version < '6.0'
      Additionals::Gemify.install_assets plugin_id
      Additionals::Gemify.create_plugin_hint plugin_id
    end
  end
end
