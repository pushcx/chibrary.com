require File.dirname(__FILE__) + '/../test_helper'

class GenericControllerTest < ActionController::TestCase
  context "on GET to /about" do
    setup do
      get :about
    end

    should_respond_with :success
    should_render_template :about
    should_not_set_the_flash
  end

  context "on GET to /search" do
    setup do
      get :search
    end

    should_respond_with :success
    should_render_template :about
    should_not_set_the_flash
  end
end
