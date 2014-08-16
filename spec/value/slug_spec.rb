require_relative '../rspec'
require_relative '../../value/slug'

module Chibrary

describe Slug do
  describe '::new' do
    it 'takes a string' do
      expect(Slug.new('slug')).to be_a(Slug)
    end

    it 'raises if a slug is too long' do
      expect { Slug.new '01234567890123456789x' }.to raise_error(InvalidSlug)
    end

    it 'raises if a slug is blank' do
      expect { Slug.new '' }.to raise_error(InvalidSlug)
    end

    it 'raises if a slug contains non-alpha characters' do
      expect { Slug.new 'abc#123' }.to raise_error(InvalidSlug)
    end

    it 'accepts digits in slugs' do
      expect(Slug.new('1')).to be_a(Slug)
    end

    it 'accepts - and _ in slugs' do
      expect(Slug.new('a-_b')).to be_a(Slug)
    end
  end

  describe '#==' do
    it 'is equal to other Slugs with same content' do
      expect(Slug.new('a')).to eq(Slug.new('a'))
    end

    it 'is equal to strings with same content (meh)' do
      expect(Slug.new('a')).to eq('a')
    end

    it 'is not equal to different Slugs/strings' do
      expect(Slug.new('a')).to_not eq(Slug.new('b'))
      expect(Slug.new('a')).to_not eq('b')
    end
  end
end

end
