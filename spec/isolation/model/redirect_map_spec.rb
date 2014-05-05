require_relative '../../rspec'
require_relative '../../../value/sym'
require_relative '../../../model/redirect_map'

describe RedirectMap do
  describe "#redirect" do
    it "raises if redirecting to its own year + month" do
      rm = RedirectMap.new Sym.new('slug', 2014, 4)
      expect {
        rm.redirect ['aaaaaaaa'], 2014, 4
      }.to raise_error(CircularRedirect)
    end
  end
end
