#!/usr/bin/ruby

require 'net/pop'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'mail'
require 'filer'

class Fetcher < Filer
  def source
    'subscription'
  end

  def setup
    # create POP3 connection
    @pop = Net::POP3.new(MAIL_SERVER, MAIL_POP3_PORT)
    @pop.open_timeout = 300
    #@pop.set_debug_output $stderr
    @pop.start(MAIL_USER, MAIL_PASSWORD)
    $stdout.puts "#{@pop.n_mails} to process:"
  end

  def acquire
    @pop.delete_all do |mail|
      begin
        yield mail.mail
      rescue SequenceExhausted
        teardown
        return
      end
    end
  end

  def teardown
    @pop.finish
  end
end


Fetcher.new.run if __FILE__ == $0
