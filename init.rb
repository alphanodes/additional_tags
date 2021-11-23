# frozen_string_literal: true

require 'additional_tags/plugin_version'

Redmine::Plugin.register :additional_tags do
  name        'Additional Tags'
  author      'AlphaNodes GmbH'
  description 'Redmine tagging support'
  version     AdditionalTags::PluginVersion::VERSION
  url         'https://github.com/alphanodes/additional_tags/'
  author_url  'https://alphanodes.com/'
  directory __dir__

  requires_redmine version_or_higher: '4.1'

  settings default: Additionals.load_settings('additional_tags'),
           partial: 'additional_tags/settings/settings'

  project_module :issue_tracking do
    permission :create_issue_tags, {}
    permission :edit_issue_tags, {}
    permission :view_issue_tags, {}, read: true
  end

  project_module :wiki do
    permission :add_wiki_tags, wiki: %i[update_tags]
  end

  menu :admin_menu,
       :additional_tags,
       { controller: 'settings', action: 'plugin', id: 'additional_tags' },
       caption: :field_tags
end

if Rails.version > '6.0'
  ActiveSupport.on_load(:active_record) { AdditionalTags.setup }
else
  Rails.configuration.to_prepare { AdditionalTags.setup }
end
