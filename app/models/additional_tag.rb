# frozen_string_literal: true

class AdditionalTag
  GROUP_SEP = '::'

  def initialize(name:, disable_grouping: false)
    @tag_name = name
    @disable_grouping = disable_grouping
  end

  def tag_bg_color
    @tag_bg_color ||= "##{Digest::SHA256.hexdigest(tag_name)[0..5]}"
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

  def tag_name
    group? ? group_name : @tag_name
  end

  def group_labels
    @group_labels ||= @tag_name.split GROUP_SEP
  end

  def group_name
    if group_labels.length > 2
      group_labels[0...-1].join GROUP_SEP
    else
      group_labels.first
    end
  end

  def group_value
    group_labels.last
  end

  def group?
    !@disable_grouping && group_labels.length > 1
  end
end
