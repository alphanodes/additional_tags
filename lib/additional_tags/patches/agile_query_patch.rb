# frozen_string_literal: true

module AdditionalTags
  module Patches
    module AgileQueryPatch
      extend ActiveSupport::Concern

      included do
        include Additionals::Concerns::Query
        prepend InstanceOverwriteMethods
        include InstanceMethods

        add_available_column ::QueryTagsColumn.new
      end

      module InstanceOverwriteMethods
        def initialize_available_filters
          super

          initialize_tags_filter if !available_filters.key?('tags') &&
                                    User.current.allowed_to?(:view_issue_tags, project, global: true)
        end
      end

      module InstanceMethods
        def sql_for_tags_field(field, _operator, values)
          build_sql_for_tags_field_with_permission klass: queried_class,
                                                   operator: operator_for(field),
                                                   values:,
                                                   permission: :view_issue_tags
        end
      end
    end
  end
end
