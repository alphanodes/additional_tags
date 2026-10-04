# Changelog

## 4.7.0

- Requires Redmine 7.0.2 or higher, which fixes two security issues of Redmine core
- Tags are sorted alphabetically in any script (Cyrillic, Chinese, Japanese, ...) independent of the database, also in the issue tag dialog. Tags with the same count are sorted by name when a list is sorted by count
- Editing several issues at once and tag lists load their tags in one query instead of one per entry
- The `issue_tag` macro renders each issue as one link with its state classes, so closed issues are struck through including the subject
- The descriptions of the issue tag macros explain visibility, project scope and defaults

## 4.6.0

- Requires Redmine 7.0 or higher and Ruby 3.3 or higher
- Tag names are stripped of surrounding whitespace on save and when searching for tagged records
- Negated tag filters ("is not") keep the entries without any tag. The agile board tag filter uses the same logic as the issue filter
- The tag list without a valid tag type responds with 422 instead of an internal error
- Tag pills are centered on the surrounding text instead of its baseline
- The tag list label shows the custom field description as tooltip like other attributes
- All patches use `prepend` instead of `alias_method`, which avoids conflicts with other plugins extending the same methods
- additionals is enforced as required plugin

## 4.5.0

- CSV import supports issue tags, with shared building blocks for other taggable plugins #74
- Scoped tag pills no longer wrap onto two lines on narrow screens #67
- Upgrades are more robust: NOT NULL columns, idempotent migrations and a fix for copying unsaved records #76
- Saved values of the tag settings select are preselected correctly
- Visible tags of issue lists are loaded in one batch instead of one query per issue
- `AdditionalTags.fg_color` provides contrast-aware text colors for other plugins

## 4.4.0

- Replaced the acts-as-taggable-on gem with an own tagging implementation (`AdditionalTag`, `AdditionalTagging`). Unused tagger and context columns are removed by migration
- Tag search is case and accent insensitive on all databases
- Fixed an XSS vulnerability in the rendering of the most used tags
- Colors and font sizes use CSS variables instead of hardcoded values
- The tag list partial accepts a custom `label` for other plugins
- HTML requests to the tag list without a supported type redirect to the plugin settings instead of responding with 406
- `tag_names` class method for taggable models

## 4.3.0

- Requires Redmine 6.1 or higher
- New wiki macros `issue_tag` and `issue_tag_count`
- Saved queries migrated from the redmineup_tags plugin keep working
- Compatibility with Rails 8.1

## 4.2.0

- Fixed the tag filters "none" and "any"
- Buttons are hidden in the print view
- Fixed the wiki page title with tags
- Fixed a compatibility issue with other plugins #72

## 4.1.0

- Fixed the sidebar on mobile devices and the admin menu items
- Fixed the tag field label of issues and wiki pages
- Fixed table names in joins

## 4.0.0

- Requires Redmine 6.0 or higher
- Redmine 6 SVG icons, CSS variables for colors
- Removed a duplicated database index

## 3.4.0

- Maintenance release without functional changes

## 3.3.2

- Fixed the version number of the release

## 3.3.1

- Fixed the version number of the release

## 3.3.0

- Requires Ruby 3.1 or higher
- New hook to control the tags on the wiki page view
- The setting to show tags after the queries in the sidebar is a common setting
- Compatibility with Redmine 6 and Rails 7.2

## 3.2.0

- New setting to show the tags after the queries in the issue sidebar, with hooks before and after the tags sidebar
- Fixed templates in the sidebar
- Fixed a problem with the asset pipeline
- Better compatibility of the `issues_with` override with other plugins

## 3.1.0

- Requires Ruby 3.0 or higher
- acts-as-taggable-on updated to 10.0
- Tags are not saved if issue tags are disabled
- `to_list` renamed to `to_comma_list` to fix a conflict with other plugins #56

## 3.0.9

- API support for unsaved tags, e.g. for webhooks
- Fixed copying issues with tags in bulk, which removed common tags
- Adding tags with the context menu creates a journal entry #39
- Fixed compatibility with other plugins (e.g. agile) when checking tag permissions #40
- Fixed the plugin version #54

## 1.0.7

- Tag groups: tags with `::` are split into group name and value, all tags of a group get the same color (scoped tags)
- Admins can choose the tag colors (color theme), a background color can be assigned to a tag
- Tag grouping is disabled when tags are used without color
- Parent projects can access the tags of their subprojects #36
- Fixed removing tags with issue bulk edit
- The context menu offers "Add tags" and "Edit tags" for issues
- Tags of a query column are preloaded
- Compatibility with the RedmineUP plugins agile and contact_helpdesk #40 and redmine_checklists

## 1.0.6

- `with_tags` of wiki pages can exclude a page
- Faster removal of unused tags

## 1.0.5

- Requires Redmine 5.0 or higher
- API support for the tag list, fixed creating new issues with tags #21
- Tags in the sidebar work with custom issue controllers #23

## 1.0.4

- New tag style with tag count, without icons
- Tags are hidden in the API if the permission is missing or tags are disabled
- Fixed queries with a deleted tag
- Unused tags are removed by a background job
- Fixed N+1 queries and faster migration

## 1.0.3

- Dashboard block instead of the reports integration
- Fixed selecting tags with bulk edit
- Fixed wiki pages with multiple tags
- Compatibility with Ruby 3 and Rails 6

## 1.0.2

- Fixed deleting tags without relations #12
- Fixed the tag export
- Fixed the namespace of the query column

## 1.0.1

- acts-as-taggable-on updated to 7.0
- Filters "none" and "any" for tags, also for issue tags on time entries
- Faster tag filter, fixed negation filter with multiple tags
- Fixed bulk edit removing existing tags #10
- Fixed permissions for adding wiki tags
- Wiki tags of all projects in the wiki namespace

## 1.0.0

- First release with tags for issues and wiki pages
