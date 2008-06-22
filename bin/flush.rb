#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

if ARGV.empty?
  puts "call with one or more slug[/year[/month]]"
  exit
end

# build list of months to flush
jobs = []
ARGV.each do |url|
  slug, year, month = url.split('/')

  if year and month
    jobs << { :slug => slug, :year => year, :month => month }
  else
    prefix = "render/month/#{slug}/"
    prefix += "#{year}/" if year
    $cachedhash[prefix].each do |key|
      y, m= key.split('/')[2..-1]
      jobs << { :slug => slug, :year => y, :month => m }
    end
  end
end

thread_queue = CachedHash.new 'thread_queue'

jobs.each do |job|
  slug, year, month = job[:slug], job[:year], job[:month]

  # delete threading job
  $cachedhash.delete "thread_queue/#{slug}/#{year}/#{month}"

  # delete render jobs
  $cachedhash["render_queue/#{slug}/#{year}/#{month}"].each do |key|
    $cachedhash.delete key
  end

  # delete message cache
  $archive.delete "list/#{slug}/message/#{year}/#{month}"

  # delete thread cache
  $archive["list/#{slug}/thread/#{year}/#{month}"].each do |key|
    $archive.delete key
  end

  # delete render/month
  $cachedhash.delete "render/month/#{slug}/#{year}/#{month}"

  # queue rethread
  thread_queue["#{slug}/#{year}/#{month}"] = ''
end
