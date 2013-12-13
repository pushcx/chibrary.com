require_relative '../../rspec'
require_relative '../../../model/storage/list_storage'

describe ListStorage do
  context 'instantiated with a List' do
    it "generates a key based on list" do
      list = List.new :slug
      expect(ListStorage.new(list).extract_key).to eq('/slug')
    end

    describe "generating a hash" do
      let(:list) { List.new('slug', 'name', 'description', 'homepage') }
      let(:list_storage) { ListStorage.new(list) }
      subject { list_storage.to_hash }

      it { expect(subject[:slug]).to eq('slug') }
      it { expect(subject[:homepage]).to eq('homepage') }
      it { expect(subject[:name]).to eq('name') }
      it { expect(subject[:description]).to eq('description') }
    end
  end

  describe "::build_key" do
    it "builds a key based on slug" do
      expect(ListStorage.build_key('slug')).to eq('/slug')
    end
  end

  describe "::from_hash" do
    it "creates Lists" do
      list = ListStorage.from_hash({
        slug: 'slug',
        name: 'name',
        description: 'description',
        homepage: 'homepage',
      })
      expect(list.slug).to eq('slug')
      expect(list.name).to eq('name')
      expect(list.description).to eq('description')
      expect(list.homepage).to eq('homepage')
    end

    it "doesn't error on incomplete hashes" do
      list = ListStorage.from_hash({ slug: 'slug' })
      expect(list.slug).to eq('slug')
      expect(list.homepage).to be_nil
    end
  end

  describe "::find" do
    it "instantiates a list from the bucket" do
      bucket = double('bucket')
      bucket.should_receive(:[]).with('/slug').and_return({
        slug: 'slug',
        name: 'name',
      })
      ListStorage.should_receive(:bucket).and_return(bucket)
      list = ListStorage.find('slug')
      expect(list).to be_a(List)
      expect(list.slug).to eq('slug')
      expect(list.name).to eq('name')
    end
  end
end
