# frozen_string_literal: true

module AdditionalTags
  module Utils
    module_function

    def using_postgresql?
      ActiveRecord::Base.connection.adapter_name.downcase.include? 'postgresql'
    end

    def using_mysql?
      ActiveRecord::Base.connection.adapter_name.downcase.include? 'mysql'
    end

    def like_operator
      using_postgresql? ? 'ILIKE' : 'LIKE'
    end

    def escape_like(str)
      str.to_s.gsub('!', '!!').gsub('%', '!%').gsub('_', '!_')
    end
  end
end
