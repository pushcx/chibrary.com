#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

class Publisher
  def run
    # happens here in case list desc, etc. changes
    rsync_cachedhash

    @rc = RemoteConnection.new
    Queue.new(:publish).work do |job|
      rsync_month job[:slug], job[:year], job[:month]
      flush job[:slug], job[:year], job[:month]
    end

    # flush to add any new lists to homepage
    @rc.remove "listlibrary.net/current/public/index.html"
  end

  def flush(slug, year, month)
    @rc.remove "listlibrary.net/current/public/#{slug}.html"
    @rc.remove "listlibrary.net/current/public/#{slug}/#{year}/#{month}.html"
    @rc.rmdir  "listlibrary.net/current/public/#{slug}/#{year}/#{month}"
  end

  def rsync_cachedhash
    `/usr/bin/rsync -a --delete --exclude=in_progress/ --exclude=sequence/ --exclude=queue/ -e "ssh -C" listlibrary_cachedhash/ listlibrary@listlibrary.net:~/listlibrary_cachedhash`
  end

  def rsync_month(slug, year, month)
    %w{thread thread_list}.each do |data|
      `/usr/bin/rsync -a --delete -e "ssh -C" listlibrary_archive/list/#{slug}/#{data}/#{year}/#{month}* listlibrary@listlibrary.net:~/listlibrary_archive/list/#{slug}/#{data}/#{year}/`
    end
  end
end

begin
  Publisher.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
