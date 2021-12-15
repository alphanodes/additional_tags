# frozen_string_literal: true

require File.expand_path '../../test_helper', __FILE__

class WelcomeControllerTest < AdditionalTags::ControllerTest
  fixtures :projects, :news, :users, :members,
           :dashboards

  def setup
    Setting.default_language = 'en'
    User.current = nil
  end

  def test_show_with_left_welcome_block
    @request.session[:user_id] = 4
    with_settings welcome_text: 'Welcome here' do
      get :index

      assert_response :success
      assert_select 'div#list-left div#block-welcome', text: /Welcome here/
    end
  end
end
