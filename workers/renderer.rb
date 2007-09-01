#!/usr/bin/ruby

# There are three kinds of jobs in the render queue:
# render_queue/slug                        - render the list description
# render_queue/slug/year/month             - render monthly thread list
# render_queue/slug/year/month/call_number - render/delete a thread

require 'rubygems'
require 'cgi'
require 'haml'
require 'net/sftp'
require 'net/ssh'
require 'ostruct'

require 'aws'
require 'list'

class View
  def self.render options={}
    locals = (options[:locals] or {})
    if locals[:collection]
      return locals[:collection].collect do |item|
        locals[options[:partial]] = item
        View.render options.merge({ :collection => nil, :locals => locals })
      end.join("\n")
    end

    locals[:title] = (locals[:title].to_s + " - ListLibrary").strip.sub(/^- /, '')

    filename = (options[:page] or options[:partial])
    if options[:page]
      Haml::Engine.new(File.read("view/layout.haml"), :locals => locals, :filename => "layout").render(View) do
        Haml::Engine.new(File.read("view/#{filename}.haml"), :locals => locals, :filename => filename).render(View)
      end
    elsif options[:partial]
      Haml::Engine.new(File.read("view/#{filename}.haml"), :locals => locals, :filename => filename).render(View)
    end
  end

  # helpers

  def self.compress_quotes str
    str.gsub(/(^-{4,}[^-]{8,}-{4,}\n.*|(^[^\n]{10,}:\n\n?|)(^&gt;.*?=(20|)\n.*?\n|^&gt;.*?\n)+\n*)/m) do
      '<blockquote>' + $1.sub(/(.*)\n+/m, '\1') + "</blockquote>\n"
    end
  end

  def self.h str
    str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([a-z]+)/, '\1@\2...\3') # hide mail addresses
    str = CGI::escapeHTML(str)
    str.gsub(/(\w+:\/\/[^\s]+)/m, '<a href="\1' + '">\1</a>') # link urls
  end

  def self.message_partial message
    if message.nil? or message.is_a? Symbol
      'message_missing'
    elsif message.no_archive?
      'message_no_archive'
    else
      'message'
    end
  end

  def self.subject message
    s = Message.normalize_subject(message.subject)
    (s.empty? ? '<i>no subject</i>' : s)
  end
end

class Renderer
  attr_accessor :jobs, :stop_on_empty

  def initialize
    @jobs = []
    @stop_on_empty = false
  end

  def get_job
    if @jobs.empty?
      exit if @stop_on_empty
      @jobs = AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => 'render_queue/')
    end
    @jobs.pop
  end

  def render_list slug
    years = {}
    AWS::S3::Bucket.keylist('listlibrary_cachedhash', "inventory/#{slug}/").each do |key|
      year, month = key.split('/')[2..-1]
      years[year] ||= {}
      years[year][month] = AWS::S3::S3Object.load_yaml(key, "listlibrary_cachedhash")
    end
    html = View::render(:page => "list", :locals => {
      :years     => years,
      :list      => List.new(slug),
      :slug      => slug,
    })
    upload_page "#{slug}/index.html", html
  end

  def render_month slug, year, month
    html = View::render(:page => "month", :locals => {
      :threadset => ThreadSet.month(slug, year, month),
      :inventory => AWS::S3::S3Object.load_yaml("inventory/#{slug}/#{year}/#{month}", "listlibrary_cachedhash"),
      :list      => List.new(slug),
      :slug      => slug,
      :year      => year,
      :month     => month,
    })
    upload_page "#{slug}/#{year}/#{month}/index.html", html
  end

  def render_thread slug, year, month, call_number
    html = View::render :page => "thread", :locals => {
      :thread => AWS::S3::S3Object.load_yaml("list/#{slug}/thread/#{year}/#{month}/#{call_number}"),
      :list      => List.new(slug),
      :slug      => slug,
      :year      => year,
      :month     => month,
    }
    upload_page "#{slug}/#{year}/#{month}/#{call_number}", html
  end

  def delete_thread slug, year, month, call_number
    ssh_connection do |ssh|
      ssh.sftp.connect do |sftp|
        sftp.remove("listlibrary.net/#{slug}/#{year}/#{month}/#{call_number}") rescue Net::SFTP::Operations::StatusException
      end
    end
    nil
  end

  def run
    render_queue = CachedHash.new("render_queue")

    while job = get_job
      slug, year, month, call_number = job.key.split('/')[1..-1]
      $stdout.puts [slug, year, month, call_number].compact.join('/')
      job.delete

      if call_number # render/delete a thread
        if AWS::S3::S3Object.exists? "list/#{slug}/thread/#{year}/#{month}/#{call_number}", "listlibrary_archive"
          $stdout.puts 'thread'
          render_thread slug, year, month, call_number
        else
          delete_thread slug, year, month, call_number
        end
        render_queue["#{slug}/#{year}/#{month}"] = ''
      elsif year and month # render monthly thread list
        $stdout.puts 'month'
        render_month slug, year, month
        render_queue["#{slug}"] = ''
      else # render list info page
        $stdout.puts 'list'
        render_list  slug
      end
    end
  end

  def upload_page filename, str
    tmpname = "#{Process.pid}-#{rand(1000000)}"
    dirs = filename.split('/')
    filename = dirs.pop
    path = "listlibrary.net"

    ssh_connection do |ssh|
      ssh.sftp.connect do |sftp|
        sftp.open_handle("tmp/#{tmpname}", "w") do |handle|
          sftp.write(handle, str)
          sftp.fsetstat(handle, :permissions => 644)
        end
        dirs.each do |dir|
          path += "/#{dir}"
          sftp.mkdir path, :mode => 755 rescue Net::SFTP::Operations::StatusException
        end
      end
      ssh.process.popen3("/bin/mv /home/listlibrary/tmp/#{tmpname} /home/listlibrary/#{path}/#{filename}")
    end
  end

  def ssh_connection
    Net::SSH.start("listlibrary.net", "listlibrary", "JemUQc7h", :compression => 'zlib', :compression_level => 9) do |ssh|
      yield ssh
    end
  end
end

if __FILE__ == $0
  r = Renderer.new
  ARGV.each { |job| r.jobs << OpenStruct.new(:key => "render_queue/#{job}", :delete => nil) }
  r.stop_on_empty = true
  r.run
end
