class AdditionalTagsRemoveUnusedTagJob < AdditionalTagsJob
  def perform
    AdditionalTags.remove_unused_tags
  end
end
