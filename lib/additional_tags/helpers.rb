# frozen_string_literal: true

module AdditionalTags
  # Global, because tag fields are part of forms of other controllers and
  # plugins, for example the issue form through a view hook
  module Helpers
    # Label of a tag input field, its title explains scoped and grouped tags
    def additional_tags_label_tag(name, text = l(:field_tag_list))
      label_tag name, additional_tags_field_name(text)
    end

    # Name of a tag input field with the explanation of scoped and grouped
    # tags as title, like the description of a custom field
    def additional_tags_field_name(text = l(:field_tag_list))
      tag.span text, class: 'field-description', title: additional_tags_field_hint
    end

    # Grouped tags only exist with colors, the rule of scoped tags always applies
    def additional_tags_field_hint
      hints = [l(:text_scoped_tags_hint)]
      hints.unshift l(:text_grouped_tags_hint) if AdditionalTags.use_colors?
      hints.join ' '
    end
  end
end
