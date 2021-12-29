# frozen_string_literal: true

class AdditionalTagsRemoveUnusedTagJob < AdditionalTagsJob
  def perform
    # only once a minute to reduce load
    cache_key = self.class.to_s
    return if Rails.cache.read(cache_key) && !Rails.env.test?

    Rails.cache.write cache_key, true, expires_in: 60
    AdditionalTags::Tags.remove_unused_tags
  end
end
