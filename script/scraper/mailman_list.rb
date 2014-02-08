#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'hpricot'
require 'open-uri'

class ScrapeMailmanList
  def run
    import_mailman = Queue.new :import_mailman

    import_mailman.work do |job|
      slug, name, homepage = job[:slug], job[:name], job[:url]
      print "Default slug #{slug}: "
      slug = gets.chomp
      slug = job[:slug] if slug.empty?
      slug = slug.downcase
      while list = ListStorage.find(slug) and list.homepage != homepage
        print "Slug #{slug} taken, enter new: "
        slug = gets.chomp.downcase
      end

      list.name = name unless name.empty?
      list.homepage = homepage
      ListStorage.new(list).store

      Hpricot(open(homepage)).search("//a").each do |a|
        puts "#{a} #{a.inner_html =~ /archive/i}"
      end

      exit
    end
  end
end

begin
  ScrapeMailmanList.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
