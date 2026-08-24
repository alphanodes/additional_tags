# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

# Validates that all Deface overrides from additional_tags still match their target elements
# in the templates they are anchored to.
#
# Overrides belong to this plugin by the prefix of their name, so overrides built from
# :text are covered as well.
#
class AdditionalTagsDefaceOverridesTest < AdditionalTags::TestCase
  def test_all_deface_overrides_have_valid_hashes
    assert_deface_overrides_valid name_prefix: 'additional-tags'
  end
end
