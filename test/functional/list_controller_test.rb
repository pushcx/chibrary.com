require File.dirname(__FILE__) + '/../test_helper'

class ListControllerTest < ActionController::TestCase
  context "on GET to /show" do
    setup do
      # mock list object
      @list = mock('list', :slug => 'slug')
      @list.expects(:[]).with('name').times(2).returns('Example List')
      @list.expects(:[]).with('homepage').returns(nil)
      @list.expects(:[]).with('description').returns(nil)
      $archive.expects(:has_key?).returns(true)
      List.expects(:new).returns(@list)

      # mock snippets
      $archive.expects(:[]).with('snippet/list/slug').returns([])

      # mock for thread table in view
      ThreadList.expects(:year_counts).returns([])

      get :show, :slug => @list.slug
    end

    should_respond_with :success
    should_render_template :show
    should_not_set_the_flash
    should_assign_to :list, :snippets
  end

  should "redirect years" do
    @list = mock('list', :slug => 'slug')
    get :year_redirect, :slug => @list.slug, :year => 2001
    assert_redirected_to :action => :show
  end
end
