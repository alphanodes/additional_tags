# frozen_string_literal: true

class AdditionalTag
  GROUP_SEP = ':'
  SCOPE_SEP = '::'

  class << self
    def valid_mutually_exclusive_tag(tag_list)
      return true if tag_list.blank?

      tags = tag_list.select { |t| t.include? SCOPE_SEP }
      return true if tags.blank?

      groups = tags.map { |t| new(name: t).group_name }
      groups == groups.uniq
    end
  end

  # NOTE: only use bg_color parameter, if background color should not
  #       calculated by AdditionalTag - if you want to assign manual color
  def initialize(name:, disable_grouping: false, color_theme: nil, bg_color: nil)
    @tag_name = name.to_s
    @disable_grouping = disable_grouping
    @color_theme = color_theme.to_s
    @bg_color = bg_color
  end

  def name_for_color
    # different colors for non-grouped, grouped and scoped tag
    name = if scoped? || grouped?
             "#{group_name}#{sep}"
           else
             tag_name
           end

    if @color_theme.present? && @color_theme != '0' && @color_theme != '1'
      "#{name}#{@color_theme}"
    else
      name
    end
  end

  def tag_bg_color
    @tag_bg_color ||= @bg_color || "##{Digest::SHA256.hexdigest(name_for_color)[0..5]}"
  end

  # calculate contrast text color according to YIQ method
  # https://24ways.org/2010/calculating-color-contrast/
  # https://stackoverflow.com/questions/3942878/how-to-decide-font-color-in-white-or-black-depending-on-background-color
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
    scoped? ? group_name : @tag_name
  end

  def labels
    @labels ||= scoped? ? scope_labels : group_labels
  end

  def scope_labels
    @scope_labels ||= @tag_name.split(SCOPE_SEP).map(&:strip)
  end

  def group_labels
    @group_labels ||= @tag_name.split(GROUP_SEP).map(&:strip)
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
    !@disable_grouping && scope_labels.length > 1
  end

  def grouped?
    !@disable_grouping && group_labels.length > 1
  end
end
