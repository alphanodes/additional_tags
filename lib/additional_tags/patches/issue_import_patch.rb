# frozen_string_literal: true

module AdditionalTags
  module Patches
    module IssueImportPatch
      extend ActiveSupport::Concern

      included do
        include AdditionalTags::Concerns::ImportWithTags
      end
    end
  end
end
