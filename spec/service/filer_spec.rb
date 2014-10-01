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
      list = double('List', slug: 'slug')
      ListRepo.should_receive(:for).with('slug', ['user@example.com']).and_return(list)
      mr = double('MessageRepo', sym: 'sym')
      mr.should_receive(:store)
      MessageRepo.should_receive(:new).and_return(mr)
      MessageRepo.should_receive(:has_message_id?).and_return(false)

      f.file "From: user@example.com\n\nBody", 'slug'
    end
  end

  describe '#thread_jobs' do
    it 'queues workers' do
      filer = Filer.new 'source'
      filer.instance_variable_set(:@filed, { 'subject' => ['callnumb'] })
      ThreadWorker.should_receive(:perform_async).with(['callnumb'])
      filer.thread_jobs
    end
  end
end

end # Chibrary
