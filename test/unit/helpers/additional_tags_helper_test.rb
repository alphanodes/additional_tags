# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__

class AdditionalTagsHelperTest < AdditionalTags::HelperTest
  include AdditionalTagsHelper

  # The order itself is tested with AdditionalTag.sort_for_list
  def test_sort_tags_for_list_sorts_like_the_model
    tags = tags_with_counts 'Zebra' => 1, 'Mango' => 2, 'äpfel' => 1

    assert_equal AdditionalTag.sort_for_list(tags, sort_by: 'count', sort_order: 'desc').map(&:name),
                 sort_tags_for_list(tags, sort_by: 'count', sort_order: 'desc').map(&:name)
  end

  private

  # Tags as available_tags returns them, with the count as selected column
  def tags_with_counts(counts)
    counts.map { |name, count| AdditionalTag.instantiate 'name' => name, 'count' => count }
  end
end
