# frozen_string_literal: true

module AdditionalTags
  module Patches
    module TimeEntryPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
      end

      module InstanceMethods
        def issue_tags
          return [] if issue.nil?

          issue.tags
        end
      end
    end
  end
end
