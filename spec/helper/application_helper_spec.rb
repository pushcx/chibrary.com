require_relative '../rspec'
require_relative '../../web/helper/application_helper'

module Chibrary

describe 'App Helper' do
  describe 'f' do
    it 'formats email addresses and links' do
      [
        ['a user@a.com a',               'a user@a.com a'],
        ['a user@hp.com a',              'a user@hp...com a'],
        ['a user@ibm.com a',             'a user@ib...com a'],
        ['a user@example.com a',         'a user@ex...com a'],
        ['a user@example.co.uk a',       'a user@ex...uk a'],
        ['mailto:user@example.co.uk',    'mailto:user@ex...uk'],
        ["To: ruby-doc@ruby-lang.org\n", "To: ruby-doc@ru...org\n"],
        ["a@ibm.com b@ibm.com",          "a@ib...com b@ib...com"],

        ['http://aa.com',                '<a rel="nofollow" href="http://aa.com">http://aa.com</a>'],
        ["http://bb\a.com",              "<a rel=\"nofollow\" href=\"http://bb\a.com\">http://bb\a.com</a>"],
        ['http://cc.com?a=a',            '<a rel="nofollow" href="http://cc.com?a=a">http://cc.com?a=a</a>'],
        ['http://dd.com/"',              '<a rel="nofollow" href="http://dd.com/&quot;">http://dd.com/&quot;</a>'],
        ['telnet://ee.com',              '<a rel="nofollow" href="telnet://ee.com">telnet://ee.com</a>'],

        ['http://user:pass@ff.com/foo',  '<a rel="nofollow" href="http://user:pass@ff...com/foo">http://user:pass@ff...com/foo</a>'],
      ].each do |original, cleaned|
        expect(f(original)).to eq(cleaned)
      end
    end
  end
end

end # Chibrary
