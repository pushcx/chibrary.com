#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'hpricot'
require 'open-uri'

# Takes a list of URLs like http://mail.python.org/mailman/listinfo
# and queues mailman importing jobs for all the lists it finds there.

class GetMailmanLists < Filer
  def initialize urls
    @urls = urls
  end

  def run
    import_mailman = Queue.new :import_mailman

    @urls.each do |url|
      # derive prefix from domain, prompt to ask if it's good
      prefix = url.match(/https?:\/\/([^\/]+)/).captures.first.scan(/[^.]{4,}/).last
      puts "Derived prefix '#{prefix}' from #{url}"

      doc = Hpricot(open(url))
      doc.search("//table/tr").each do |row|
        # archives are listed in a table with two cells
        next unless row.search('td').length == 2
        next unless row.search('td[1]/a/strong').length == 1

        url  = row.at('td[1]/a').attributes['href']
        mailman_slug = row.at('td[1]/a/strong').inner_html.downcase
        # use mailman's slug if it already starts with the desired prefix
        # eg. python has python-3000 and PythonCAD lists
        if mailman_slug[0...(prefix.length)] == prefix
          slug = mailman_slug
        else
          slug = "#{prefix}-#{mailman_slug}"
        end
        slug = slug[0...-2] if slug =~ /\-l$/
        name = row.at('td[2]').inner_html
        name = nil if name == "<em>[no description available]</em>"

        puts "slug '#{slug}', name '#{name}', url: #{url}"
        import_mailman.add slug: slug, name: name, url: url
      end
    end
  end
end

begin
  GetMailmanLists.new(ARGV).run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
