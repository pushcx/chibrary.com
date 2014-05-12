require 'time'

require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../model/summary'
require_relative '../../model/summary_container'
require_relative '../../repo/summary_set_repo'

describe SummarySetRepo do
  let(:now) { Time.now }
  let(:summary_containers) {
    [
      SummaryContainer.new('s1@example.com', Summary.new('callnum1', 'Foo', now, 'Blurb')),
      SummaryContainer.new('s2@example.com', Summary.new('callnum2', 'Foo', now, 'Blurb')),
    ]
  }
  let(:serialized) {
    [
      {
        key: "s1@example.com",
        value: {
          call_number: "callnum1",
          n_subject: "Foo",
          date: now.rfc2822,
          blurb: "Blurb",
        },
        children: [],
      },
      {
        key: "s2@example.com",
        value: {
          call_number: "callnum2",
          n_subject: "Foo",
          date: now.rfc2822,
          blurb: "Blurb",
        },
        children: [],
      },
    ]
  }

  context 'instantiated with a list of SummaryContainers' do
    it '#extract_key' do
      ssr = SummarySetRepo.new(Sym.new('slug', 2014, 1), [])
      expect(ssr.extract_key).to eq('slug/2014/01')
    end

    it '#serialize' do
      ssr = SummarySetRepo.new(Sym.new('slug', 2014, 1), summary_containers)
      expect(ssr.serialize).to eq(serialized)
    end
  end

  it '#deserialize' do
    expect(SummarySetRepo.deserialize(serialized)).to eq(summary_containers)
  end
end
