# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start :rails do
    add_filter 'init.rb'
    root File.expand_path "#{File.dirname __FILE__}/.."
  end
end

require File.expand_path "#{File.dirname __FILE__}/../../../test/test_helper"
require File.expand_path "#{File.dirname __FILE__}/../../additionals/test/global_test_helper"
require File.expand_path "#{File.dirname __FILE__}/../../additionals/test/crud_controller_base"

module AdditionalTags
  module TestHelper
    include Additionals::GlobalTestHelper

    def prepare_tests
      Role.where(id: [1, 2, 3]).each do |r|
        r.permissions << :view_issue_tags
        r.save
      end

      Role.where(id: [1, 2]).each do |r|
        r.permissions << :edit_issue_tags
        r.save
      end

      Role.where(id: [1]).each do |r|
        r.permissions << :create_issue_tags
        r.permissions << :add_wiki_tags
        r.save
      end
    end
  end

  module PluginFixturesLoader
    def fixtures(*table_names)
      dir = "#{File.dirname __FILE__}/fixtures/"
      table_names.each do |x|
        ActiveRecord::FixtureSet.create_fixtures dir, x if File.exist? "#{dir}/#{x}.yml"
      end
      super table_names
    end
  end

  class IntegrationTest < Redmine::IntegrationTest
    extend PluginFixturesLoader
  end

  class ApiTest < Redmine::ApiTest::Base
    extend PluginFixturesLoader
  end

  class ControllerTest < Redmine::ControllerTest
    include AdditionalTags::TestHelper
    extend PluginFixturesLoader

    def fixture_files_path
      Rails.root.join('plugins/additional_tags/test/fixtures/files').to_s
    end
  end

  class TestCase < ActiveSupport::TestCase
    include AdditionalTags::TestHelper
    extend PluginFixturesLoader
  end
end
