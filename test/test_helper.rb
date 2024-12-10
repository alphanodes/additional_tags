# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start :rails do
    add_filter 'init.rb'
    root File.expand_path "#{File.dirname __FILE__}/.."
  end
end

require File.expand_path "#{File.dirname __FILE__}/../../../test/test_helper"
require File.expand_path "#{File.dirname __FILE__}/../../additionals/test/global_fixtures_helper"
require File.expand_path "#{File.dirname __FILE__}/../../additionals/test/global_test_helper"

module AdditionalTags
  module TestHelper
    include Additionals::GlobalTestHelper

    def prepare_tests
      Role.where(id: [1, 2, 3]).find_each do |r|
        r.permissions << :view_issue_tags
        r.save
      end

      Role.where(id: [1, 2]).find_each do |r|
        r.permissions << :edit_issue_tags
        r.save
      end

      Role.where(id: [1]).find_each do |r|
        r.permissions << :create_issue_tags
        r.permissions << :add_wiki_tags
        r.save
      end
    end
  end

  module PluginFixturesLoader
    include Additionals::GlobalFixturesHelper

    def plugin_fixture_path
      "#{File.dirname __FILE__}/fixtures"
    end

    def plugin_fixtures_list
      %i[dashboards additional_tags additional_taggings]
    end
  end

  class IntegrationTest < Redmine::IntegrationTest
    extend PluginFixturesLoader
    fixtures(*fixtures_list)
  end

  class ApiTest < Redmine::ApiTest::Base
    include AdditionalTags::TestHelper
    extend PluginFixturesLoader
    fixtures(*fixtures_list)
  end

  class ControllerTest < Redmine::ControllerTest
    include AdditionalTags::TestHelper
    extend PluginFixturesLoader
    fixtures(*fixtures_list)

    def fixture_files_path
      Rails.root.join('plugins/additional_tags/test/fixtures/files').to_s
    end
  end

  class TestCase < ActiveSupport::TestCase
    include AdditionalTags::TestHelper
    extend PluginFixturesLoader
    fixtures(*fixtures_list)
  end
end
