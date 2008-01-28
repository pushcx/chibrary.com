#!/usr/bin/ruby

require 'net/pop'

MAX_MAILS = 1_000_000
PER_CONNECTION = 500

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'mail'
require 'filer'
require 'log'

class Fetcher < Filer
  def initialize server=nil, sequence=nil, max=PER_CONNECTION
    @max = [max.to_i, PER_CONNECTION].min
    super server, sequence
  end

  def source
    'subscription'
  end

  def setup
    # create POP3 connection
    @pop = Net::POP3.new(MAIL_SERVER, MAIL_POP3_PORT)
    @pop.open_timeout = 300
    @pop.read_timeout = 300
    @pop.start(MAIL_USER, MAIL_PASSWORD)
    @log = Log.new "Fetcher"
  end

  def acquire
    @log.block "pop3", "#{@pop.n_mails} available, fetching a max of #{@max}" do |log|
      @pop.each_mail do |mail|
        begin
          raise Net::POPError if mail.mail.nil? or mail.mail == ''
          yield mail.mail, :do
          mail.delete
          return if (@max -= 1) <= 0
        rescue Net::POPError => e
          # just rebuild the connection and soldier on
          log.warning "rebuilding after #{e.class}: #{e.message}"
          teardown rescue nil
          setup
        rescue SequenceExhausted
          return
        end
      end
    end
  end

  def teardown
    @pop.finish
  end
end

if __FILE__ == $0
  max = (ARGV.shift or MAX_MAILS).to_i
  fetched = 0
  log = Log.new "Fetcher"
  log.block "fetcher", "up to #{max} messages" do |log|
    while max > 0
      run = Fetcher.new(nil, nil, max).run
      puts run
      fetched += run
      break if run < 10
      sleep 10
      max -= PER_CONNECTION
    end
    "fetched #{fetched}"
  end
end
