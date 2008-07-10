#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"
# Fetches and refiles every stored message.
# Useful for dicking with every message to add a header or something.

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
