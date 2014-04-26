require_relative '../../rspec'
require_relative '../../../model/redirect_map'

describe RedirectMap do
  describe "#redirect" do
    it "takes call numbers" do
      rm = RedirectMap.new 'slug', 2014, 5
      rm.redirect [CallNumber.new('aaaaaaaa')], 2014, 4
      expect(rm.redirects).to eq({ 'aaaaaaaa' => [2014, 4]})
    end
  end
end
