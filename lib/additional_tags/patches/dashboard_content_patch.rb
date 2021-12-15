# frozen_string_literal: true

module AdditionalTags
  module Patches
    module DashboardContentPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def block_definitions
          blocks = super

          blocks['issue_tags'] = {
            label: l(:field_issue_tags),
            permission: :view_issue_tags,
            if: proc { AdditionalTags.setting?(:active_issue_tags) },
            async: { partial: 'dashboards/blocks/issue_tags' }
          }

          blocks
        end
      end
    end
  end
end
