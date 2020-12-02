# Additional Tags - Tags for Redmine

[![Rate at redmine.org](https://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](https://www.redmine.org/plugins/additional_tags) [![Run Linters](https://github.com/AlphaNodes/additional_tags/workflows/Run%20Linters/badge.svg)](https://github.com/AlphaNodes/additional_tags/actions?query=workflow%3A%22Run+Linters%22) [![Run Brakeman](https://github.com/AlphaNodes/additional_tags/workflows/Run%20Brakeman/badge.svg)](https://github.com/AlphaNodes/additional_tags/actions?query=workflow%3A%22Run+Brakeman%22) [![Run Tests](https://github.com/AlphaNodes/additional_tags/workflows/Tests/badge.svg)](https://github.com/AlphaNodes/additional_tags/actions?query=workflow%3ATests)


## Features

- Tags for issues
- Tags for wiki pages
- Accented and non-latin characters supported for tag order
- View, edit and create tag permissions for issues
- Create permission for wiki tags
- Managing tags
- custom tags and tagging tables (additional_tags and additional_taggings). If a other plugin
  used tags or tagging tables for issue or wiki tagging, there tags will be migrated automatically
- based on very popular [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on)

Other models are support with plugins, which uses additional_tags as framework. At the moment this are:

- redmine_db (db entry tagging)
- redmine_passwords (password tagging)
- redmine_reporting (project tagging)
- redmine_hrm (holiday tagging)
- redmine_servicedesk (contact tagging)


## Requirements

- Ruby `>= 2.4.10`
- Redmine `>= 4.1.0`
- Redmine plugins: [additionals]((https://www.redmine.org/plugins/additionals))

## Installing

Choose 1a OR 1b

1a. Clone this repository into `redmine/plugins/additional_tags`.

```shell
cd redmine/plugins
git clone https://github.com/alphanodes/additionals.git
git clone https://github.com/alphanodes/additional_tags.git
```

1b. Add the gem to your Gemfile.local:

```ruby
gem 'additional_tags'
```

At the moment, additionals should be installed before using gem method. In later versions
addtionals plugins is usable as gem, too.

2. Install dependencies and migrate database.

```shell
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

3. Restart your Redmine web server.


## Running tests

Make sure you have the latest database structure loaded to the test database:

```shell
bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
```

After you cloned the plugin, run the following command:

```shell
rake redmine:plugins:test RAILS_ENV=test NAME=additional_tags
```

## Uninstall

```shell
rake redmine:plugins:migrate NAME=additional_tags VERSION=0
```

After this remove REDMINE/plugins/additional_tags directory.


## License

This plugin is licensed under the terms of GNU/GPL v2.
See LICENSE for details.


## Credits

The source code is a (almost) rewrite of

  - [redmine_tags](https://github.com/ixti/redmine_tags)
  - [redmineup_tags](https://www.redmine.org/plugins/redmineup_tags)

Special thanks to the original author and contributors for making this awesome hook for Redmine.
