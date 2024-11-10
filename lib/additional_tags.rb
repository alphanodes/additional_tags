# frozen_string_literal: true

require 'acts-as-taggable-on'

module AdditionalTags
  VERSION = '4.0.0-main'

  TAG_TABLE_NAME = 'additional_tags'
  TAGGING_TABLE_NAME = 'additional_taggings'

  include RedminePluginKit::PluginBase

  class << self
    def show_sidebar_tags?
      setting(:tags_sidebar).present? && setting(:tags_sidebar) != 'none'
    end

    # color is used by default (if setting is missing, too)
    def use_colors?
      setting(:tags_color_theme).to_s != '0'
    end

    private

    def setup
      begin
        Redmine::Plugin.find 'additionals'
      rescue Redmine::PluginNotFound
        # rubocop: disable Style/RaiseArgs
        raise Redmine::PluginRequirementError.new "#{plugin_id} plugin requires the additionals plugin. " \
                                                  'Please install additionals plugin (https://github.com/alphanodes/additionals)'
        # rubocop: enable Style/RaiseArgs
      end

      ActsAsTaggableOn.tags_table = TAG_TABLE_NAME
      ActsAsTaggableOn.taggings_table = TAGGING_TABLE_NAME
      # NOTE: remove_unused_tags cannot be used, because tag is deleted before assign for tagging
      # @see https://github.com/mbleigh/acts-as-taggable-on/issues/946
      # NOTE2: merging tags is not compatible, too.
      ActsAsTaggableOn.remove_unused_tags = false

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
end
