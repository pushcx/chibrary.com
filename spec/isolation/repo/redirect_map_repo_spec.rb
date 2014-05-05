require_relative '../../rspec'
require_relative '../../../value/sym'
require_relative '../../../repo/redirect_map_repo'

describe RedirectMapRepo do
  context 'instantiated with a RedirectMap' do
    it "generates a key based on sym" do
      rm = RedirectMap.new sym_collaborator
      RedirectMapRepo.new(rm).extract_key
    end

    describe "#serialize" do
      let(:rm) { rm = RedirectMap.new Sym.new('slug', 2014, 4), { 'aaaaaaaa' => [2014, 3] } }
      let(:redirect_map_repo) { RedirectMapRepo.new(rm) }
      subject { redirect_map_repo.serialize }

      it { expect(subject.count).to eq(1) }
      it { expect(subject.keys.first).to eq( 'aaaaaaaa' ) }
      it { expect(subject.values.first).to eq( [2014, 3] ) }
    end
  end

  describe "::build_key" do
    it "delegates key building to sym" do
      RedirectMapRepo.build_key(sym_collaborator)
    end
  end

  describe "::find" do
    it "instantiates a RedirectMap from the bucket" do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('slug/2014/04').and_return({
        'aaaaaaaa' => [2014, 3],
      })
      RedirectMapRepo.should_receive(:bucket).and_return(bucket)
      rm = RedirectMapRepo.find(Sym.new('slug', 2014, 4))
      expect(rm).to be_a(RedirectMap)
      expect(rm['aaaaaaaa']).to eq([2014,3])
    end
  end
end
