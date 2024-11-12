# frozen_string_literal: true

loader = RedminePluginKit::Loader.new plugin_id: 'additional_tags'

Redmine::Plugin.register :additional_tags do
  name 'Additional Tags'
  author 'AlphaNodes GmbH'
  description 'Redmine tagging support'
  version AdditionalTags::VERSION
  url 'https://github.com/alphanodes/additional_tags/'
  author_url 'https://alphanodes.com/'
  requires_redmine version_or_higher: '6.0'

  settings default: loader.default_settings,
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
       caption: :field_tags,
       plugin: 'additionals',
       icon: 'tags'
end

RedminePluginKit::Loader.persisting { loader.load_model_hooks! }
