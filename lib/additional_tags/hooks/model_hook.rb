# frozen_string_literal: true

module AdditionalTags
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        AdditionalTags.setup!
      end
    end
  end
end
