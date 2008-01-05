#!/usr/bin/ruby

require 'net/pop'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'mail'
require 'filer'
require 'log'

class Fetcher < Filer
  def initialize server=nil, sequence=nil, max=1000
    @max = max.to_i
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
    #@pop.set_debug_output $stderr
    @pop.start(MAIL_USER, MAIL_PASSWORD)
    Log << "#{@pop.n_mails} available, fetching a max of #{@max}:"
  end

  def acquire
    @pop.each_mail do |mail|
      begin
        yield mail.mail
        mail.delete
        return if (@max -= 1) <= 0
      rescue SequenceExhausted
        return
      end
    end
  end

  def teardown
    Log << "done"
    @pop.finish
  end
end


if __FILE__ == $0
  f = Fetcher.new nil, nil, ARGV.shift
  f.run
end
