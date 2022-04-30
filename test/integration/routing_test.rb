# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class RoutingTest < Redmine::RoutingTest
  def test_auto_completes
    should_route 'GET /auto_completes/issue_tags' => 'auto_completes#issue_tags'
    should_route 'GET /auto_completes/wiki_tags' => 'auto_completes#wiki_tags'
    should_route 'GET /auto_completes/all_tags' => 'auto_completes#all_tags'
  end

  def test_additional_tags
    should_route 'GET /additional_tags' => 'additional_tags#index'
    should_route 'GET /additional_tags/1/edit' => 'additional_tags#edit', id: '1'
    should_route 'PUT /additional_tags/2' => 'additional_tags#update', id: '2'
    should_route 'POST /additional_tags/merge' => 'additional_tags#merge'
    should_route 'GET /additional_tags/context_menu' => 'additional_tags#context_menu'
    should_route 'DELETE /additional_tags' => 'additional_tags#destroy'
  end

  def test_issue_tags
    should_route 'GET /issue_tags/edit' => 'issue_tags#edit'
    should_route 'POST /issue_tags' => 'issue_tags#update'
  end

  def test_wiki_page
    should_route 'PUT /projects/foo/wiki/Page/update_tags' => 'wiki#update_tags', project_id: 'foo', id: 'Page'
  end
end
