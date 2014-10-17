#!/usr/bin/env ruby
require_relative "../config/environment"

#require 'mocha'
#require 'pp'
#require 'aws/s3'

#unless defined? AWS_connection
#  ACCESS_KEY_ID = '0B8FSQ35925T27X8Q4R2'
#  SECRET_ACCESS_KEY = 'ryM3xNKV/3OL9j5jMeJHRqSzWETxK5MeSlXj6/rv'
#  AWS_connection = AWS::S3::Base.establish_connection!(
#    :access_key_id     => ACCESS_KEY_ID,
#    :secret_access_key => SECRET_ACCESS_KEY,
#    :persistent        => false
#  )
#end
#class AWS::S3::Connection
#  def self.prepare_path(path)
#    path = path.remove_extended unless path.utf8?
#    URI.escape(path).gsub('+', '%2B')
#  end
#end
#class AWS::S3::Bucket
#  def self.keylist bucket, prefix, last=nil
#    last = prefix if last.nil?
#    loop do
#      keys = begin
#        get(path(bucket, { :prefix => prefix, :marker => last })).parsed['contents'].collect { |o| o['key'].to_s }
#      rescue NoMethodError
#        []
#      end
#      break if keys.empty?
#      keys.each { |k| yield k }
#      last = keys.last
#    end
#  end
#end

#slashed = 152
#deleted = 53348
#checkpoint = false
#AWS::S3::Bucket.keylist('listlibrary_archive', 'list') do |key|
#  checkpoint = (key == 'list/ruby-talk/message/2007/11/!&!AAAAAAAAAAAYAAAAAAAAAHa90SsA6zBLoSDNyZhKQMnCgAAAEAAAAKOo1oI/7N9AusJoLgFStUYBAAAAAA==@yahoo.fr') unless checkpoint
#  next unless checkpoint
#
#  if key =~ /\/thread\// or key =~ /\/thread_list\// or key =~ /\/message_list\//
#    deleted += 1
#    AWS::S3::S3Object.delete(key, 'listlibrary_archive')
#    next
#  end
#  next unless key =~ /\/message\/\d\d\d\d\/\d\d\/.*\/.*/
#  slashed += 1
#  puts "d(#{deleted}) s(#{slashed}) #{key}"
#  File.open("slashed/#{slashed}", 'w') { |f| f.write AWS::S3::S3Object.value(key, 'listlibrary_archive') }
#end
#puts ''
#puts "slashed: #{slashed}"
#puts "delete: #{deleted}"

fixed = 0
checkpoint = false
$archive['list'].each(true) do |key|
  next unless key.include '/message/'
  #checkpoint = (key.include? 'linux-kernel/message/2007/11') unless checkpoint
  #next unless checkpoint
  m = $archive["list/#{key}"]
  #puts key
  if m.message.is_a? AWS::S3::S3Object::Value
    fixed += 1
    puts "#{fixed} #{key}"
    m.message = m.message.to_s
    m.overwrite = :do
    m.store
  end
end
puts "fixed #{fixed}"

#i = 0
#exception_count = 0
#AWS::S3::Bucket.keylist('listlibrary_archive', '', 'list/linux-kernel/message/2007/08/46bffa66.QCw 66otGbnO9zGl%joe@perches.com') do |key|
#  i += 1
#  puts "#{i} #{key}"
#  next if key.match /\/\d\d$/
#  while 1
#    begin
#      o = AWS::S3::S3Object.find(key, 'listlibrary_archive')
#    rescue
#      print '        exception'
#      exception_count += 1
#      sleep 2
#    else
#      break
#    end
#  end
#  if key.match '/message/'
#    m = Message.new o.value, o.metadata['source'], o.metadata['call_number']
#    m.overwrite = :do
#    m.store
#  else
#    $archive[key] = o.value
#  end
#end
#puts "stored #{i} messages"
#puts "Exception count: #{exception_count}"

#class RemoteConnection
#  def initialize ; end
#  def upload_file filename, str
#    filename = "listlibrary.net/" + filename
#    puts filename
#    name, *path = filename.split(/\//).reverse
#    path = path.reverse.join '/'
#    `mkdir -p #{path}`
#    File.open(filename, 'w') do |file|
#     file.puts str
#    end
#  end
#end

# month test
#threadset = YAML::load_file('threadset')
#html = View::render(:page => "month", :locals => {
#  :threadset => threadset,
#  :inventory => AWS::S3::S3Object.load_yaml("inventory/ruby-core/2007/07", "listlibrary_cachedhash"),
#  :list      => List.new('ruby-core'),
#  :slug      => 'ruby-core',
#  :year      => '2007',
#  :month     => '07',
#})

# thread test

#Renderer.new.render_static
#Renderer.new.render_thread('ruby-core', '2007', '08', '011NY2Rw')
#Renderer.new.render_month('ruby-core', '2007', '08')
#Renderer.new.render_list('ruby-core')

# list test
#years = {}
#AWS::S3::Bucket.keylist('listlibrary_cachedhash', "inventory/ruby-core/").each do |key|
#  year, month = key.split('/')[2..-1]
#  years[year] ||= {}
#  years[year][month] = AWS::S3::S3Object.load_yaml(key, "listlibrary_cachedhash")
#end
#html = View::render(:page => "list", :locals => {
#  :years     => years,
#  :list      => List.new('ruby-core'),
#  :slug      => 'ruby-core',
#})

# about
#html = View::render(:page => "about")

# index
#lists = []
#AWS::S3::Bucket.keylist('listlibrary_cachedhash', "render/index/").each do |key|
#  lists << List.new(key.split('/')[-1])
#end
#html = View::render(:page => 'index', :locals => { :lists => lists })
#puts html

# get some messages
#messages = []
#AWS::S3::Bucket.keylist('listlibrary_archive', "list/ruby-core/message/2007/08/").each do |key|
#  $stderr.puts key
#  messages << AWS::S3::S3Object.value(key, 'listlibrary_archive').to_s
#end
#puts messages.to_yaml

#message = Message.new(YAML::load_file('00hxU04i')[:mail], 'test', '00hxU04i')
#puts message.body
#puts message.key

#ts = ThreadSet.new
#AWS::S3::Bucket.keylist('listlibrary_archive', "list/ruby-core/message/2007/08/").each do |key|
#  $stderr.puts key
#  ts << Message.new(key)
#end
#puts ts.to_yaml

#threadset = YAML::load_file('threadset')
#puts threadset.containers['46CC8CFB.6070404@davidflanagan.com'].to_yaml

#messages = YAML::load_file('test/fixture/message.yaml')
##YAML::load_file('test/fixture/complex_thread.yaml').each do |m|
#[messages['initial_message'], messages['regular_reply'], messages['quoting_reply']].each do |m|
#  ts << Message.new(m, 'test', '00000000')
#end
#ts.dump

# resets the call numbers and empties the db:
#require 'riak' ; client = Riak::Client.new(:protocol => "pbc", :pb_port => 8087) ; client.buckets.each { |b| b.keys.each { |k| b.delete k } } ; require 'redis' ; Redis.new.set 'run_id', 0

# drops all threads and redoes a couple months of mud-dev
#require 'riak' ; client = Riak::Client.new(:protocol => "pbc", :pb_port => 8087) ; b = client['thread'] ; b.keys.each { |k| b.delete k } ; MessageRepo.bucket.get_index('sym_bin', 'mud-dev/2004/03').each { |cn| ThreadWorker.new.perform([cn]) } ; MessageRepo.bucket.get_index('sym_bin', 'mud-dev/2004/04').each { |cn| ThreadWorker.new.perform([cn]) } ; MonthCountWorker.new.perform 'mud-dev/2004/03' ; MonthCountWorker.new.perform 'mud-dev/2004/04'

# exports a real thead to a yaml fixture
def fixturize call_number, filename
  t = ThreadRepo.find_with_messages(call_number)
  raw_emails = {}
  t.each { |c| raw_emails[c.call_number.to_s] = c.message.email.raw unless c.empty? }
  parentings = {}
  t.each { |c| parentings[c.message_id.to_s] = c.parent.try(:message_id).try(:to_s) }
  File.write("spec/fixture/thread/#{filename}.yaml", { parentings: parentings, raw_emails: raw_emails }.to_yaml)
  t.message_count
end
