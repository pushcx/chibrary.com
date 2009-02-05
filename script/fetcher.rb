#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'net/pop'

MAX_MAILS = 1_000_000
PER_CONNECTION = 1_000

class Fetcher < Filer
  attr_reader :n_mails

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
    @n_mails = @pop.n_mails
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
          log.warning "stopping after #{e.class}: #{e.message}"
          teardown
          return
        rescue SequenceExhausted
          return
        end
      end
    end
  end

  def teardown
    @pop.finish if @pop.started?
  end
end

if __FILE__ == $0
  max = (ARGV.shift or MAX_MAILS).to_i
  fetched = 0
  log = Log.new "Fetcher"
  log.block "fetcher", "up to #{max} messages" do |log|
    while max > 0
      fetcher = Fetcher.new(nil, nil, max)
      run = fetcher.run
      fetched += run
      break if run < 50 or (run <= fetcher.n_mails and run < PER_CONNECTION)
      sleep 15
      max -= PER_CONNECTION
    end
    "fetched #{fetched}"
  end
end
