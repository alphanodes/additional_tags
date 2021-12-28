# frozen_string_literal: true

namespace :redmine do
  namespace :additional_tags do
    desc <<-DESCRIPTION
    Remove unused tags.

    Example:
      bundle exec rake redmine:additional_tags:remove_unused_tags RAILS_ENV=production
    DESCRIPTION
    task remove_unused_tags: :environment do
      AdditionalTags::Tags.remove_unused_tags

      puts 'Unused tags has been removed.'
      exit 0
    end
  end
end
