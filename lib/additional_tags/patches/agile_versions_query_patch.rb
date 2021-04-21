# frozen_string_literal: true

module AdditionalTags
  module Patches
    module AgileVersionsQueryPatch
      extend ActiveSupport::Concern

      included do
        add_available_column ::QueryTagsColumn.new
      end
    end
  end
end
