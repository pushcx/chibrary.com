require File.dirname(__FILE__) + '/../test_helper'
require 'renderer'
require 'threading'
require 'message'

class RendererTest < Test::Unit::TestCase
  fixtures :message

  def setup
    $stdout.expects(:puts).at_least(0)
  end

  def test_get_job
    r = Renderer.new

    AWS::S3::Bucket.expects(:objects).returns(['renderer_queue/example_list/2008/08'])
    assert_equal 'renderer_queue/example_list/2008/08', r.get_job

    AWS::S3::Bucket.expects(:objects).returns([])
    assert_equal nil, r.get_job
  end
end
