#!/usr/bin/ruby
# Fetches and refiles every stored message.
# Useful for dicking with every message to add a header or something.

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'filer'

class Refiler < Filer

  def source
    'subscription'
  end

  # comment out to force messages to get new call numbers
  def call_number ; nil ; end

  def acquire
    AWS::S3::Bucket.keylist('listlibrary_archive', 'list/').each { |key| yield key }
  end

end

Refiler.new.run if __FILE__ == $0
