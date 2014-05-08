require_relative '../rspec'
require_relative '../../model/list'

describe List do
  describe '::new' do
    it 'raises if a slug is too long' do
      expect { List.new '01234567890123456789x' }.to raise_error(InvalidSlug)
    end

    it 'raises if a slug contains non-alpha characters' do
      expect { List.new 'abc#123' }.to raise_error(InvalidSlug)
    end

    it 'accepts - and _ in list slugs' do
      expect { List.new 'a-_b' }.not_to raise_error
    end
  end

  it '#slug' do
    expect(List.new('slug').slug).to eq('slug')
  end

  describe '#title_name' do
    it 'returns the name if there is one' do
      expect(List.new('slug', 'Name').title_name).to eq('Name')
    end

    it 'falls back to slug with no name' do
      expect(List.new('slug').title_name).to eq('slug')
    end
  end

  describe '#==' do
    it 'is equal if fields match' do
      l1 = List.new('slug', 'name', 'description', 'homepage')
      l2 = List.new('slug', 'name', 'description', 'homepage')
      expect(l1).to eq(l2)
    end

    it 'is not equal in case of difference' do
      l1 = List.new('slug')
      l2 = List.new('foo')
      expect(l1).not_to eq(l2)
    end
  end
end
