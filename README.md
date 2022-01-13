# Additional Tags - Tags for Redmine

[![Rate at redmine.org](https://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](https://www.redmine.org/plugins/additional_tags) [![Run Linters](https://github.com/AlphaNodes/additional_tags/workflows/Run%20Linters/badge.svg)](https://github.com/AlphaNodes/additional_tags/actions?query=workflow%3A%22Run+Linters%22) [![Run Tests](https://github.com/AlphaNodes/additional_tags/workflows/Tests/badge.svg)](https://github.com/AlphaNodes/additional_tags/actions?query=workflow%3ATests)

## Features

- Tags for issues
- Tags for wiki pages
- Accented and non-latin characters supported for tag order
- View, edit and create tag permissions for issues
- Create permission for wiki tags
- Managing tags
- Custom tags and tagging tables (additional_tags and additional_taggings). If a other plugin
  used tags or tagging tables for issue or wiki tagging, there tags will be migrated automatically
- Based on the very popular [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on)

![screenshot](https://raw.githubusercontent.com/AlphaNodes/additional_tags/master/doc/images/additional-tags.gif)

Other plugins use additional_tags as framework in order to support tags for their entities.
At the moment this are:

- redmine_db (db entry tagging)
- redmine_passwords (password tagging)
- redmine_reporting (project tagging)
- redmine_hrm (holiday tagging)
- redmine_servicedesk (contact tagging)

Start using it, too. The example image shows the centralized tag management in the plugin configuration.

![screenshot](https://raw.githubusercontent.com/AlphaNodes/additional_tags/master/doc/images/additional-tags-framework.png)

## Why another Tag plugin?

1. Main reason: a stable tag solution for a current Redmine version is needed - NOW
2. Other plugins are no longer maintained or not available on a public community plattform as github or gitlab
3. Redmine (core) does not support tags. A feature request for issue tags exists since 2008, see [#1448](https://www.redmine.org/issues/1448).
4. Lots of plugins are using its own tag implementation (redmine_knowledgebase, redmine_contacts, redmine_products, redmine_passwords, redmine_db, ....). A common functional base was required. This plugin closes this gap. It would be great, if other plugins would use ``additional_tags`` for it.

## Requirements

- Redmine `>= 4.1.0`
- Ruby `>= 2.6`
- Redmine plugins: [additionals](https://www.redmine.org/plugins/additionals)

## Installing

### 1. Get right plugin version

To install stable version of additional_tags, use

```shell
cd $REDMINE_ROOT
git clone -b stable https://www.github.com/alphanodes/additionals.git plugins/additionals
git clone -b stable https://www.github.com/alphanodes/additional_tags.git plugins/additional_tags
```

It is also possible to use stable version as a gem package as an alternative. If you want it, add this to your $REDMINE_ROOT/Gemfile.local:

```ruby
gem 'additional_tags'
```

At the moment, additionals should be installed before using gem method. In later versions
addtionals plugins is usable as gem, too.

If you want to use the latest development version, use

```shell
cd $REDMINE_ROOT
git clone https://github.com/alphanodes/additionals.git plugins/additionals
git clone https://github.com/alphanodes/additional_tags.git plugins/additional_tags
```

### 2. Install dependencies and migrate database.

```shell
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### 3. Restart your Redmine web server.

## Running tests

Make sure you have the latest database structure loaded to the test database:

```shell
bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
```

Run the following command to start tests:

```shell
bundle exec rake redmine:plugins:test NAME=additional_tags RAILS_ENV=test
```

## Migrate from other plugin

If you use [redmine_tags](https://github.com/ixti/redmine_tags) or [redmineup_tags](https://www.redmine.org/plugins/redmineup_tags) you can migrate your tags.
``additional_tags`` uses its own database tables, to prevent conflicts with other plugins (e.g. redmine_knowledgebase, redmine_contacts, etc)
To migrate your data to ``additional_tags`` use the following steps (order is important):

1. Remove plugin directory of your old plugin, e.g plugin/redmine_tags
2. Install ``additional_tags`` as is descript above (this automatically migrate data to new tables)

The old database tables are existing after these steps.

## Uninstall

```shell
cd $REDMINE_ROOT
bundle exec rake redmine:plugins:migrate NAME=additional_tags VERSION=0 RAILS_ENV=production
rm -rf plugins/additional_tags
```

## License

This plugin is licensed under the terms of GNU/GPL v2.
See LICENSE for details.

## Credits

The source code is a (almost) rewrite of

- [redmine_tags](https://github.com/ixti/redmine_tags)
- [redmineup_tags](https://www.redmine.org/plugins/redmineup_tags)

Special thanks to the original author and contributors for making this awesome hook for Redmine.
