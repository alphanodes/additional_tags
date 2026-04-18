# frozen_string_literal: true

class AdditionalTag < ApplicationRecord
  GROUP_SEP = ':'
  SCOPE_SEP = '::'

  attr_accessor :disable_grouping, :color_theme, :bg_color

  has_many :taggings,
           dependent: :destroy,
           class_name: 'AdditionalTagging',
           foreign_key: :tag_id,
           inverse_of: :tag

  validates :name, presence: true,
                   uniqueness: { case_sensitive: true },
                   length: { maximum: 255 }

  scope :named, ->(name) { where "LOWER(#{table_name}.name) = ?", name.to_s.downcase }
  scope :named_any, lambda { |list|
    list = Array(list).map { |t| t.to_s.downcase }
    where "LOWER(#{table_name}.name) IN (?)", list
  }
  scope :most_used, ->(limit = 20) { order(taggings_count: :desc).limit limit }

  class << self
    def find_or_create_all_with_like_by_name(*list)
      list = list.flatten
      list.compact!
      list.map!(&:strip)
      list.compact_blank!
      list.uniq!
      return [] if list.empty?

      existing = named_any(list).to_a
      list.map do |name|
        existing.detect { |t| t.name.casecmp(name).zero? } ||
          create!(name: name)
      rescue ActiveRecord::RecordNotUnique
        named(name).first || raise
      end
    end

    def mutually_exclusive_tags?(tag_list)
      return true if tag_list.blank?

      tags = tag_list.select { |t| t.include? SCOPE_SEP }
      return true if tags.blank?

      groups = tags.map { |t| new(name: t).group_name }
      groups == groups.uniq
    end
  end

  def ==(other)
    super || (other.is_a?(self.class) && name == other.name)
  end

  delegate :to_s, to: :name

  def count
    self[:count].to_i
  end

  def name_for_color
    color_name = if scoped? || grouped?
                   "#{group_name}#{sep}"
                 else
                   tag_name
                 end

    if color_theme.present? && color_theme != '0' && color_theme != '1'
      "#{color_name}#{color_theme}"
    else
      color_name
    end
  end

  def tag_bg_color
    @tag_bg_color ||= bg_color || "##{Digest::SHA256.hexdigest(name_for_color)[0..5]}"
  end

  def tag_fg_color
    @tag_fg_color ||= begin
      r = tag_bg_color[1..2].hex
      g = tag_bg_color[3..4].hex
      b = tag_bg_color[5..6].hex
      (r * 299 + g * 587 + b * 114) >= 128_000 ? 'black' : 'white'
    end
  end

  def sep
    scoped? ? SCOPE_SEP : GROUP_SEP
  end

  def tag_name
    scoped? ? group_name : name.to_s
  end

  def labels
    @labels ||= scoped? ? scope_labels : group_labels
  end

  def scope_labels
    @scope_labels ||= name.to_s.split(SCOPE_SEP).map(&:strip)
  end

  def group_labels
    @group_labels ||= name.to_s.split(GROUP_SEP).map(&:strip)
  end

  def group_name
    if labels.length > 2
      labels[0...-1].join sep
    else
      labels.first
    end
  end

  def group_value
    labels.last
  end

  def scoped?
    !disable_grouping && scope_labels.length > 1
  end

  def grouped?
    !disable_grouping && group_labels.length > 1
  end
end
