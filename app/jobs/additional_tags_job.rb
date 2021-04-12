# frozen_string_literal: true

class AdditionalTagsJob < AdditionalsJob
  queue_as :additional_tags
end
