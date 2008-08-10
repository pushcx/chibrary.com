#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

class Publisher
  def run
    # happens here in case list desc, etc. changes
    rsync_cachedhash
    rsync_homepage_snippets

    @rc = RemoteConnection.new
    Queue.new(:publish).work do |job|
      rsync_month job[:slug], job[:year], job[:month]
      rsync_list_snippets job[:slug]
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

  def rsync_homepage_snippets
    `/usr/bin/rsync -a --delete -e "ssh -C" listlibrary_archive/snippet/homepage listlibrary@listlibrary.net:~/listlibrary_archive/snippet`
  end

  def rsync_list_snippets slug
    `/usr/bin/rsync -a --delete -e "ssh -C" listlibrary_archive/snippet/list/#{slug} listlibrary@listlibrary.net:~/listlibrary_archive/snippet/list`
  end
end

begin
  Publisher.new.run if __FILE__ == $0
rescue Exception => e
  puts "#{e.class}: #{e}\n" + e.backtrace.join("\n")
end
