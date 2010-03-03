require 'test_helper'

class LogMessagesControllerTest < ActionController::TestCase
  context "creating a log message" do
    setup do
      post :create, :log_message => {
        :server  => '1',
        :pid     => '123',
        :worker  => '101',
        :key     => 'threader',
        :status  => 'status',
        :message => 'Test message.'
      }
    end

    should_respond_with :success
    should_change("The number of log messages", :by => 1) { LogMessage.count }
  end
end
