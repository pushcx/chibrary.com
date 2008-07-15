#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

class Publisher
  def run
    rsync

    Queue.new(:publish).work do |job|
      flush job[:slug], job[:year], job[:month]
    end
  end

  def rsync
    `/usr/bin/rsync -a --delete --exclude=in_progress/ --exclude=sequence/ --exclude=queue/ -e "ssh -C" listlibrary_cachedhash/ listlibrary@listlibrary.net:~/listlibrary_cachedhash`
    # should this next change to just rsync up a given slug/year/month and make that part of flush()?
    # might be necessary as the archive gets huge and the overhead of building the file list is painful
    `/usr/bin/rsync -a --delete --exclude=filer_failure/ --exclude=_listlibrary_no_list --exclude=message/ --exclude=message_list/ -e "ssh -C" listlibrary_archive/ listlibrary@listlibrary.net:~/listlibrary_archive`
  end

  def flush(slug, year, month)
    @rc ||= RemoteConnection.new
    @rc.remove "listlibrary.net/current/public/#{slug}.html"
    @rc.remove "listlibrary.net/current/public/#{slug}/#{year}/#{month}.html"
    @rc.rmdir  "listlibrary.net/current/public/#{slug}/#{year}/#{month}"
  end
end

begin
  Publisher.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
