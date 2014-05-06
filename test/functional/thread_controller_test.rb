require File.dirname(__FILE__) + '/../test_helper'

class ThreadControllerTest < ActionController::TestCase
  context "on GET to show" do
    setup do
      @list = mock_list
    end

    should "show messages" do
      # save myself from the creeping horror that is testing the entire
      # controller + view of these complicated data structures I'm about to
      # rebuild anyways. Gotta find a way to write view tests.
      @controller.expects(:render)
      @controller.expects(:thread_previous_next).returns ['previous', 'next']
      @list.expects(:[]).with('marker').returns('marker')

      ThreadList.expects(:new).returns mock('thread_list', redirect?: false)
      $archive.expects(:[]).with('list/slug/thread/2009/09/00000000').returns mock('thread', subject: 'subject')
      get :show, slug: 'slug', year: '2009', month: '09', call_number: '00000000'
      assert_response :success
    end

    should "raise 404s" do
      # test load_thread
      assert_raises ActionController::RoutingError do
        $archive.expects(:[]).times(2).raises NotFound
        get :show, slug: @list.slug, year: '2009', month: '09', call_number: '12345678'
      end
    end
  end

  should_eventually 'test thread_previous_next'
end
