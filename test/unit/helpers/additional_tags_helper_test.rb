# frozen_string_literal: true

require File.expand_path '../../../test_helper', __FILE__

class AdditionalTagsHelperTest < AdditionalTags::HelperTest
  include AdditionalTagsHelper

  # Tags with the same count are sorted by name, like the SQL order in available_tags
  def test_sort_tags_for_list_by_count_desc_sorts_equal_counts_by_name
    tags = tags_with_counts 'Zebra' => 1, 'äpfel' => 1, 'Birne' => 1, 'Mango' => 2, 'kiwi' => 1

    assert_equal %w[Mango äpfel Birne kiwi Zebra],
                 sort_tags_for_list(tags, sort_by: 'count', sort_order: 'desc').map(&:name)
  end

  def test_sort_tags_for_list_by_count_asc_sorts_equal_counts_by_name
    tags = tags_with_counts 'Zebra' => 1, 'Mango' => 2, 'äpfel' => 1, 'kiwi' => 2, 'Birne' => 1

    assert_equal %w[äpfel Birne Zebra kiwi Mango],
                 sort_tags_for_list(tags, sort_by: 'count', sort_order: 'asc').map(&:name)
  end

  private

  # Tags as available_tags returns them, with the count as selected column
  def tags_with_counts(counts)
    counts.map { |name, count| AdditionalTag.instantiate 'name' => name, 'count' => count }
  end
end
