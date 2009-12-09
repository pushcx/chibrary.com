require File.dirname(__FILE__) + '/../test_helper'

class MonthControllerTest < ActionController::TestCase
  context "on GET to show" do
    setup do
      @list = mock_list
    end

    should "show messages" do
      thread_list = mock('thread_list', :message_count => 1)
      @controller.expects(:month_previous_next).returns(['previous', 'next'])
      @list.expects(:thread_list).returns(thread_list)

      threadset = mock('threadset')#, :length => 1)
      ThreadSet.expects(:month).with('slug', '2009', '09').returns(threadset)

      # save myself from the creeping horror that is testing the entire
      # controller + view of these complicated data structures I'm about to
      # rebuild anyways. Gotta find a way to write view tests.
      @controller.expects(:render)

      get :show, :slug => @list.slug, :year => '2009', :month => '09'
      assert_response :success
    end

    should "show 404s" do
      assert_raises ActionController::RoutingError do
        @list.expects(:thread_list).returns(mock :message_count => 0)
        get :show, :slug => @list.slug, :year => '2009', :month => '09'
      end
    end
  end
end
