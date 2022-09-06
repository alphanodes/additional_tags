# frozen_string_literal: true

class AdditionalTagsRemoveUnusedTagJob < AdditionalTagsJob
  def perform
    if Rails.env.test?
      # no cache for testing
      AdditionalTags::Tags.remove_unused_tags
    else
      # only once a minute to reduce load
      cache = ActiveSupport::Cache::MemoryStore.new expires_in: 1.minute
      cache.fetch self.class.to_s do
        AdditionalTags::Tags.remove_unused_tags
        true
      end
    end
  end
end
