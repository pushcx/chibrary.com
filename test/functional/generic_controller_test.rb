require File.dirname(__FILE__) + '/../test_helper'

class GenericControllerTest < ActionController::TestCase
  context "on GET to /about" do
    setup { get :about }

    should_respond_with :success
    should_render_template :about
    should_not_set_the_flash
  end

  context "on GET to /search" do
    setup { get :search }

    should_respond_with :success
    should_render_template :search
    should_not_set_the_flash
  end

  context "on GET to /" do
    setup do
      $archive.expects(:[]).with('list').returns([])
      $archive.expects(:[]).with('snippet/homepage').returns([])
      get :homepage
    end

    should_respond_with :success
    should_assign_to :lists, :snippets
    should_render_template :homepage
    should_not_set_the_flash
  end
end
