require File.dirname(__FILE__) + '/../test_helper'
require 'permutation'

class ContainerTest < ThreadingTest
  context 'a cachedhash' do

    should 'cache a snippet' do
      c = Container.new ''
      body = ">The\nfirst\nfive\n\nunquoted\nnonblank\nlines"
      snippet = {
        :excerpt => "first five unquoted nonblank lines",
        :subject => 'subject',
        :url => '/slug/2009/02/00000000',
      }
      c.expects(:n_subject).returns(snippet[:subject])
      c.expects(:date).times(4).returns(Time.at(1234232107))
      c.expects(:call_number).returns('00000000')
      c.expects(:n_subject).returns('subject')
      c.expects(:effective_field).with(:slug).returns('slug')
      c.expects(:effective_field).with(:body).returns(body)
      c.expects(:last_snippet_key).with('snippet/list/slug').returns(0)
      $archive.expects(:[]=).with('snippet/list/slug/8765767892', snippet)
      c.expects(:last_snippet_key).with('snippet/homepage').returns(0)
      $archive.expects(:[]=).with('snippet/homepage/8765767892', snippet)
      c.cache_snippet
    end

    should_eventually 'ensure snippet times are reasonable'
    # cache_snippet should test to see that timestamps are within the last day
    # and not in the future

    should_eventually 'test last_snippet_key'

  end
end
