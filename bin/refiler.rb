#!/usr/bin/ruby
# Fetches and refiles every stored message.
# Useful for dicking with every message to add a header or something.

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'filer'

class Refiler < Filer

  def source
    'subscription'
  end

  # define this to force a slug; handy for mailing list imports
  #def slug ; 'linux-kernel' ; end

  # comment out to force messages to get new call numbers
  #def call_number ; nil ; end

  def acquire
    $archive['list'].each(true) do |key|
      next unless key.match '/message/'
      yield key, :do
    end
  end

end

Refiler.new.run if __FILE__ == $0
