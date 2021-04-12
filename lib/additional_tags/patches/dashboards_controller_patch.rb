# frozen_string_literal: true

module AdditionalTags
  module Patches
    module DashboardsControllerPatch
      extend ActiveSupport::Concern

      included do
        helper :additional_tags
      end
    end
  end
end
