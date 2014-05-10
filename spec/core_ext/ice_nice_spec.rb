# encoding: UTF-8

require_relative '../rspec'
require_relative '../../lib/core_ext/ice_nine_'

TestUnfrozen = Struct.new :foo
TestFrozen = Struct.new :foo do
  prepend IceNine::DeepFreeze
end

describe IceNine::DeepFreeze do
  describe 'unfrozen' do
    it "can be modified" do
      o = TestUnfrozen.new :a
      o.foo = :b
      expect(o.foo).to eq(:b)
    end
  end

  describe 'frozen' do
    it "cannot be modified" do
      o = TestFrozen.new :a
      expect {
        o.foo = :b
      }.to raise_error(RuntimeError, /can't modify/)
    end
  end
end
