#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'

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
    AWS::S3::Bucket.keylist('listlibrary_cachedhash', prefix).each do |key|
      y, m= key.split('/')[2..-1]
      jobs << { :slug => slug, :year => y, :month => m }
    end
  end
end

thread_queue = CachedHash.new 'thread_queue'

jobs.each do |job|
  slug, year, month = job[:slug], job[:year], job[:month]

  # delete threading job
  AWS::S3::S3Object.delete("thread_queue/#{slug}/#{year}/#{month}", 'listlibrary_cachedhash')

  # delete render jobs
  AWS::S3::Bucket.keylist('listlibrary_cachedhash', "render_queue/#{slug}/#{year}/#{month}").each do |key|
    AWS::S3::S3Object.delete(key, 'listlibrary_cachedhash')
  end

  # delete message cache
  AWS::S3::S3Object.delete("list/#{slug}/message_cache/#{year}/#{month}", 'listlibrary_archive')

  # delete thread cache
  AWS::S3::Bucket.keylist('listlibrary_archive', "list/#{slug}/thread/#{year}/#{month}").each do |key|
    AWS::S3::S3Object.delete(key, 'listlibrary_archive')
  end

  # delete render/month
  AWS::S3::S3Object.delete("render/month/#{slug}/#{year}/#{month}", 'listlibrary_cachedhash')

  # queue rethread
  thread_queue["#{slug}/#{year}/#{month}"] = ''
end
