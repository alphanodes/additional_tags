# frozen_string_literal: true

module AdditionalTags
  VERSION = '4.5.0-main'

  include RedminePluginKit::PluginBase

  class << self
    def show_sidebar_tags?
      setting(:tags_sidebar).present? && setting(:tags_sidebar) != 'none'
    end

    # color is used by default (if setting is missing, too)
    def use_colors?
      setting(:tags_color_theme).to_s != '0'
    end

    # Returns 'black' or 'white' -- whichever contrasts better on the given
    # hex background color (#rrggbb) -- using the YIQ brightness formula.
    # Shared so other plugins (e.g. redmine_reporting counter boxes) can pick a
    # readable text color for an arbitrary user-configured background.
    def fg_color(bg_hex)
      r = bg_hex[1..2].hex
      g = bg_hex[3..4].hex
      b = bg_hex[5..6].hex
      (r * 299 + g * 587 + b * 114) >= 128_000 ? 'black' : 'white'
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

      ActiveSupport.on_load(:active_record) { include AdditionalTags::Taggable }

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
                          IssueImport
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

      # Macros
      loader.load_macros!

      # Load view hooks
      loader.load_view_hooks!
    end
  end
end
