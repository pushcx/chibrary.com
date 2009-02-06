#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../../config/boot'
require "#{RAILS_ROOT}/config/environment"

class Maildir < Filer
  attr_reader :slug

  def initialize server=nil, sequence=nil, maildir=nil, slug=nil, unlink=False
    raise "Usage: bin/maildir.rb path/to/maildir [slug] [unlink]" if maildir.nil?
    @maildir = maildir
    @slug = slug
    @unlink = unlink
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
      file = IO.read(File.join(tmp, filename))
      next if file.nil? or file == ''
      yield file, :dont
      if @unlink
        File.unlink File.join(tmp, filename)
      else
        File.rename(File.join(tmp, filename), File.join(cur, filename))
      end
    end
  end
end

Maildir.new(nil, nil, ARGV.shift, ARGV.shift, ARGV.shift).run if __FILE__ == $0
