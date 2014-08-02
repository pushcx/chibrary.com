require_relative '../rspec'
require_relative '../../value/sym'
require_relative '../../service/filer'

module Chibrary

describe Filer do
  describe '#file' do
    it 'puts strings into MessageRepo' do
      cns = double('CallNumberService')
      CallNumberService.should_receive(:new).and_return(cns)
      f = Filer.new 'source'

      cns.should_receive(:next!).and_return('callnumb')
      list = double('List')
      ListAddressRepo.should_receive(:find_list_by_addresses).with(['user@example.com']).and_return(list)
      mr = double('MessageRepo', sym: 'sym')
      mr.should_receive(:store)
      MessageRepo.should_receive(:new).and_return(mr)

      f.file "From: user@example.com\n\nBody"
    end
  end

  describe '#thread_jobs' do
    it 'queues workers' do
      filer = Filer.new 'source'
      filer.instance_variable_set(:@syms_seen, [Sym.new('slug', 2014, 5)])
      ThreadWorker.should_receive(:perform_async).with('slug', 2014, 5)
      filer.thread_jobs
    end
  end
end

end # Chibrary
