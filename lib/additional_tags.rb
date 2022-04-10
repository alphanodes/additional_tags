# frozen_string_literal: true

require 'redmine_plugin_kit'
require 'acts-as-taggable-on'

module AdditionalTags
  TAG_TABLE_NAME = 'additional_tags'
  TAGGING_TABLE_NAME = 'additional_taggings'

  include RedminePluginKit::PluginBase

  class << self
    def show_sidebar_tags?
      setting(:tags_sidebar).present? && setting(:tags_sidebar) != 'none'
    end

    private

    def setup
      raise 'Please install additionals plugin (https://github.com/alphanodes/additionals)' unless Redmine::Plugin.installed? 'additionals'

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
                          DashboardContent
                          Journal
                          Query
                          IssuesController
                          ImportsController
                          QueriesHelper
                          SettingsController
                          TimeEntry
                          TimelogController
                          WikiController
                          WikiPage]

      loader.add_patch({ target: Redmine::Helpers::TimeReport,
                         patch: 'TimeReport' })

      loader.add_patch %w[IssueQuery TimeEntryQuery]

      if Redmine::Plugin.installed? 'redmine_agile'
        loader.add_patch %w[AgileQuery AgileBoardsController]
        loader.add_patch %w[AgileVersionsController AgileVersionsQuery] if AGILE_VERSION_TYPE == 'PRO version'
      end

      # Apply patches and helper
      loader.apply!

      # Load view hooks
      loader.load_view_hooks!
    end
  end

  # Run the classic redmine plugin initializer after rails boot
  class Plugin < ::Rails::Engine
    require 'additional_tags/tags'

    ActsAsTaggableOn.tags_table = TAG_TABLE_NAME
    ActsAsTaggableOn.taggings_table = TAGGING_TABLE_NAME
    # NOTE: remove_unused_tags cannot be used, because tag is deleted before assign for tagging
    # @see https://github.com/mbleigh/acts-as-taggable-on/issues/946
    # NOTE2: merging tags is not compatible, too.
    ActsAsTaggableOn.remove_unused_tags = false

    config.after_initialize do
      # engine_name could be used (additional_tags_plugin), but can
      # create some side effects
      plugin_id = 'additional_tags'

      # if plugin is already in plugins directory, use this and leave here
      next if Redmine::Plugin.installed? plugin_id

      # gem is used as redmine plugin
      require File.expand_path '../init', __dir__
      AdditionalTags.setup!
      Additionals::Gemify.install_assets plugin_id
      Additionals::Gemify.create_plugin_hint plugin_id
    end
  end
end
