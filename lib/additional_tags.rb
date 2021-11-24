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

      Additionals.incompatible_plugins(%w[redmine_tags
                                          redmine_tagging
                                          redmineup_tags], 'additional_tags')

      # Patches
      AutoCompletesController.include AdditionalTags::Patches::AutoCompletesControllerPatch
      CalendarsController.include AdditionalTags::Patches::CalendarsControllerPatch
      DashboardsController.include AdditionalTags::Patches::DashboardsControllerPatch
      DashboardAsyncBlocksController.include AdditionalTags::Patches::DashboardAsyncBlocksControllerPatch
      GanttsController.include AdditionalTags::Patches::GanttsControllerPatch
      MyController.include AdditionalTags::Patches::MyControllerPatch
      Issue.include AdditionalTags::Patches::IssuePatch
      Journal.include AdditionalTags::Patches::JournalPatch
      Query.include AdditionalTags::Patches::QueryPatch
      IssuesController.include AdditionalTags::Patches::IssuesControllerPatch
      ImportsController.include AdditionalTags::Patches::ImportsControllerPatch
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

        if Redmine::Plugin.installed? 'redmine_agile'
          AgileQuery.include AdditionalTags::Patches::AgileQueryPatch
          AgileBoardsController.include AdditionalTags::Patches::AgileBoardsControllerPatch
          if AGILE_VERSION_TYPE == 'PRO version'
            AgileVersionsController.include AdditionalTags::Patches::AgileVersionsControllerPatch
            AgileVersionsQuery.include AdditionalTags::Patches::AgileVersionsQueryPatch
          end
        end
      end

      # Hooks
      AdditionalTags::Hooks
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
