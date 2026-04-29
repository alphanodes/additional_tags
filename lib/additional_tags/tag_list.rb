# frozen_string_literal: true

module AdditionalTags
  class TagList < Array
    def initialize(*args)
      super()
      return unless args.any?

      args.flatten!
      args.compact!
      add(*args)
    end

    def add(*names)
      options = names.last.is_a?(Hash) ? names.pop : {}
      names.flatten!
      names = parse_input names, options
      names.each { |name| push name unless include_tag? name }
      self
    end

    alias << add

    def remove(*names)
      options = names.last.is_a?(Hash) ? names.pop : {}
      names.flatten!
      names = parse_input names, options
      names.each { |name| delete_if { |tag| tag.to_s.strip == name.to_s.strip } }
      self
    end

    def +(other)
      self.class.new(*to_a).concat other
    end

    def concat(other_list)
      other_list.each { |tag| add tag }
      self
    end

    def to_s
      map { |tag| tag.include?(DefaultParser::DELIMITER) ? "\"#{tag}\"" : tag }.join ', '
    end

    private

    def parse_input(names, options)
      if options[:parse]
        names.flat_map { |name| DefaultParser.parse name }
      else
        names.map! { |n| n.to_s.strip }
        names.compact_blank!
      end
    end

    def include_tag?(name)
      any? { |tag| tag.to_s.strip == name.to_s.strip }
    end
  end
end
