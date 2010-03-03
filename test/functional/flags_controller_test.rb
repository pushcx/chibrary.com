require 'test_helper'

class FlagsControllerTest < ActionController::TestCase
  context "creating a flag" do
    setup do
      post :create, :flag => {
        :slug => "example",
        :year => "2010",
        :month => "03",
        :call_number => "00000000"
      }
    end

    should_respond_with :success
    should_change("The number of flags", :by => 1) { Flag.count }
  end
end
