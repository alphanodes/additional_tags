module AdditionalTags
  module Patches
    module TimeEntryPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods
      end

      module InstanceMethods
        def tags
          return [] if issue.nil?

          issue.tags
        end
      end
    end
  end
end
