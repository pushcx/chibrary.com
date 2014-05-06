require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../value/thread_link'

describe ThreadLink do
  it 'generates hrefs' do
    tl = ThreadLink.new Sym.new('slug', 2014, 1), 'callnumber', 'subject'
    expect(tl.href).to eq('/slug/2014/01/callnumber')
  end
end
