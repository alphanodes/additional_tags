# frozen_string_literal: true

module AdditionalTags
  module Patches
    module SettingsControllerPatch
      extend ActiveSupport::Concern

      included do
        helper :additional_tags
        helper :additional_tags_issues
      end
    end
  end
end
