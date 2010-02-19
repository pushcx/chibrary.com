require File.dirname(__FILE__) + '/../test_helper'

class ApplicationControllerTest < ActionController::TestCase

  should "normalize subjects" do
    assert_equal 'subject',           @controller.send(:subject, 'subject')
    assert_equal '<i>no subject</i>', @controller.send(:subject, '')
  end
end
