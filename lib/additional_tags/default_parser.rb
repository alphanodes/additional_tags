# frozen_string_literal: true

module AdditionalTags
  module DefaultParser
    DELIMITER = ','

    module_function

    def parse(input)
      return [] if input.blank?

      raw = input.is_a?(Array) ? input.flatten.join(DELIMITER) : input.to_s.dup

      tags = []
      raw.gsub!(/"([^"]*)"/) do
        tags << Regexp.last_match(1)
        ''
      end
      raw.gsub!(/'([^']*)'/) do
        tags << Regexp.last_match(1)
        ''
      end

      tags.concat raw.split(DELIMITER)
      tags.map!(&:strip)
      tags.compact_blank!
      tags
    end
  end
end
