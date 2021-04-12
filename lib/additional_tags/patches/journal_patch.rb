# frozen_string_literal: true

module AdditionalTags
  module Patches
    module JournalPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def visible_details(user = User.current)
          details = super
          details.reject { |x| x.prop_key == 'tag_list' && !user.allowed_to?(:view_issue_tags, project) }
        end
      end
    end
  end
end
