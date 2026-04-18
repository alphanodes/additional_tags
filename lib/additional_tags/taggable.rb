# frozen_string_literal: true

module AdditionalTags
  module Taggable
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_additional_taggable
        class_attribute :preserve_tag_order, default: true

        has_many :taggings,
                 as: :taggable,
                 dependent: :destroy,
                 class_name: 'AdditionalTagging'

        has_many :base_tags,
                 through: :taggings,
                 source: :tag,
                 class_name: 'AdditionalTag'

        has_many :tag_taggings,
                 -> { includes(:tag) },
                 as: :taggable,
                 class_name: 'AdditionalTagging',
                 dependent: :destroy

        has_many :tags,
                 through: :tag_taggings,
                 source: :tag,
                 class_name: 'AdditionalTag'

        attribute :tag_list, AdditionalTags::TagListType.new

        after_save :save_tags

        include AdditionalTags::Taggable::InstanceMethods
        extend AdditionalTags::Taggable::TaggableClassMethods
      end
    end

    module TaggableClassMethods
      def all_tags
        AdditionalTag.joins(:taggings)
                     .where(AdditionalTagging.table_name => { taggable_type: base_class.name })
                     .distinct
      end

      def tagged_with(tags, any: false)
        tag_list = Array(tags).flatten
        tag_list.compact!
        tag_list.map!(&:to_s)
        tag_list.reject!(&:blank?)
        return none if tag_list.empty?

        tagging_table = AdditionalTagging.arel_table
        tag_table = AdditionalTag.arel_table

        if any
          tagged_with_any tag_list, tagging_table, tag_table
        else
          tagged_with_all tag_list, tagging_table, tag_table
        end
      end

      private

      def tagged_with_any(tag_list, tagging_table, tag_table)
        subquery = tagging_table
                   .project(Arel.sql('1'))
                   .join(tag_table).on(tagging_table[:tag_id].eq(tag_table[:id]))
                   .where(tagging_table[:taggable_id].eq(arel_table[primary_key]))
                   .where(tagging_table[:taggable_type].eq(base_class.name))
                   .where(tag_table[:name].lower.in(tag_list.map(&:downcase)))

        where "EXISTS (#{subquery.to_sql})"
      end

      def tagged_with_all(tag_list, tagging_table, tag_table)
        subquery = tagging_table
                   .project(tagging_table[:taggable_id])
                   .join(tag_table).on(tagging_table[:tag_id].eq(tag_table[:id]))
                   .where(tagging_table[:taggable_type].eq(base_class.name))
                   .where(tag_table[:name].lower.in(tag_list.map(&:downcase)))
                   .group(tagging_table[:taggable_id])
                   .having(tagging_table[:tag_id].count(true).eq(tag_list.size))

        where arel_table[primary_key].in(subquery)
      end
    end

    module InstanceMethods
      def tag_list
        unless @tag_list
          @tag_list = AdditionalTags::TagList.new(*tags.order(Arel.sql("LOWER(#{AdditionalTag.table_name}.name)")).pluck(:name))
          @tag_list_original = @tag_list.dup
        end
        @tag_list
      end

      def tag_list=(new_tags)
        parsed = case new_tags
                 when AdditionalTags::TagList
                   new_tags.to_a
                 else
                   AdditionalTags::DefaultParser.parse new_tags
                 end

        @tag_list_was = tag_list.dup unless @tag_list_changed_explicitly

        @tag_list = AdditionalTags::TagList.new(*parsed)
        @tag_list_original ||= @tag_list_was&.dup
        @tag_list_changed_explicitly = true
        super @tag_list
      end

      def tag_list_changed?
        return false unless @tag_list

        @tag_list.sort != (@tag_list_original || []).sort
      end

      def tag_list_was
        if @tag_list_changed_explicitly
          @tag_list_was || AdditionalTags::TagList.new
        elsif @tag_list_original
          @tag_list_original
        else
          tag_list.dup
        end
      end

      def reload(*args)
        @tag_list = nil
        @tag_list_was = nil
        @tag_list_original = nil
        @tag_list_changed_explicitly = false
        super
      end

      private

      def save_tags
        return unless @tag_list
        return if !@tag_list_changed_explicitly && @tag_list.sort == @tag_list_original&.sort

        new_tag_names = @tag_list.to_a

        current_taggings = taggings.not_owned.includes :tag
        current_tag_ids = current_taggings.pluck :tag_id
        current_tag_names = current_taggings.map { |t| t.tag.name }

        return if new_tag_names.sort == current_tag_names.sort

        new_tags = AdditionalTag.find_or_create_all_with_like_by_name new_tag_names
        new_tag_ids = new_tags.map(&:id)

        ids_to_remove = current_tag_ids - new_tag_ids
        taggings.where(tag_id: ids_to_remove).destroy_all if ids_to_remove.any?

        ids_to_add = new_tag_ids - current_tag_ids
        ids_to_add.each do |tag_id|
          taggings.create! tag_id: tag_id
        end

        @tag_list_changed_explicitly = false
        @tag_list_was = nil
        @tag_list_original = @tag_list.dup

        association(:tags).reset
        association(:taggings).reset
        association(:tag_taggings).reset
        association(:base_tags).reset

        true
      end
    end
  end
end
