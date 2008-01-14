#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'filer'
require 'log'

class Maildir < Filer
  def initialize server=nil, sequence=nil, maildir=nil
    raise "Usage: bin/maildir.rb path/to/maildir" if maildir.nil?
    @maildir = maildir
    super server, sequence
  end

  def source
    'archive'
  end

  def acquire
    new = File.join(@maildir, 'new')
    cur = File.join(@maildir, 'cur')
    tmp = File.join(@maildir, 'tmp')
    Dir.foreach(new) do |filename|
      begin
        File.rename(File.join(new, filename), File.join(tmp, filename))
      rescue SystemCallError
        # another scraper moved it already
        next
      end
      yield IO.read(File.join(tmp, filename))
      File.rename(File.join(tmp, filename), File.join(cur, filename))
    end
  end
end

Maildir.new(nil, nil, ARGV.shift).run if __FILE__ == $0
