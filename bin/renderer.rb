#!/usr/bin/ruby

# There are three kinds of jobs in the render queue:
# render_queue/slug                        - render the list description
# render_queue/slug/year/month             - render monthly thread list
# render_queue/slug/year/month/call_number - render/delete a thread

require 'rubygems'
require 'cgi'
require 'haml'
require 'ostruct'
require 'tidy'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'
require 'list'
require 'remote_connection'
require 'time_'

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
    html = if options[:page]
      Haml::Engine.new(File.read("view/layout.haml"), :locals => locals, :filename => "layout").render(View) do
        Haml::Engine.new(File.read("view/#{filename}.haml"), :locals => locals, :filename => filename).render(View)
      end
    elsif options[:partial]
      Haml::Engine.new(File.read("view/#{filename}.haml"), :locals => locals, :filename => filename).render(View)
    end

    unless options[:partial]
      Tidy.path = '/usr/lib/libtidy.so'
      tidy_options = {
        'doctype' => 'omit',
        'tidy-mark' => 'false',
        'show-body-only' => 'true',
        'new-blocklevel-tags' => 'pre',
      }
      Tidy.open(tidy_options) do |tidy|
        tidy.clean(html)
        $stderr.puts html unless tidy.errors.empty?
        raise "Tidy found errors rendering #{options.inspect}: \n" + tidy.errors.join("\n") unless tidy.errors.empty?
      end
    end
    html
  end

  # helpers

  def self.message_body m
    str = m.body
    str = remove_footer(str, m.slug)
    str = h(str)
    str = compress_quotes(str)
    str
  end

  def self.remove_footer str, slug
    list = List.new(slug)
    
    # remove footer
    if footer = list['footer'] and     # the list has a footer
       i = str.rindex(footer) and      # and it's here
       i + footer.length == str.length # and it's at the end
      str = str[0..(i - 1)]
    end
    str.strip
  end

  def self.compress_quotes str
    str.sub!(/-----BEGIN [GP]+ SIGNED MESSAGE-----\n.*?\n\n(.*?)\n*-----BEGIN [GP]+ SIGNATURE-----.*/m, '\1')
    str.gsub!(/(^-{4,}[^\-\n]{8,}-{4,}\n.*|(^[^\n]{10,}:\n\n?|)(^&gt;[^\n]*=(20|)\n[^\n]*\n|^&gt;[^\n]*\n(\s*?\n&gt;[^\n]*\n)*)+\n*)/m) do
      quote = $1.split(/\n/)
      quote.shift while quote.first =~ /^&gt;\s*$/
      quote.pop   while quote.last  =~ /^&gt;\s*$/
      lines = quote.length
      quote = quote.join("\n")
      if lines <= 3
        '</pre><blockquote class="short"><pre>' + quote + "</pre></blockquote><pre>\n"
      else
        '</pre><blockquote><pre>' + quote + "</pre></blockquote><pre>\n"
      end
    end
    str.strip
  end

  def self.h str
    str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([a-z]+)/, '\1@\2...\3') # hide mail addresses
    str = CGI::escapeHTML(str)
    str.gsub(/(\w+:\/\/[^\s]+)/m, '<a rel="nofollow" href="\1' + '">\1</a>') # link urls
  end

  def self.container_partial c
    if c.empty?
      View::render(:partial => 'message_missing')
    elsif c.message.no_archive
      View::render(:partial => 'message_no_archive')
    else
      # Load the full message from s3 to get body and etc.
      View::render(:partial => 'message', :locals => { :message => Message.new(c.message.key.to_s.gsub('+',' ')) })
    end
  end

  def self.subject o
    subj = o.n_subject
    (subj.empty? ? '<i>no subject</i>' : subj)
  end
end

class Renderer
  attr_accessor :jobs, :stop_on_empty

  def initialize
    @jobs = []
    @stop_on_empty = false
    @rc = RemoteConnection.new
  end

  def render_static
    %w{about search error/403 error/404}.each do |page|
      @rc.upload_file page, View::render(:page => page)
    end

    lists = []
    AWS::S3::Bucket.keylist('listlibrary_cachedhash', "render/index/").each do |key|
      lists << List.new(key.split('/')[-1])
    end
    @rc.upload_file 'index', View::render(:page => 'index', :locals => { :lists => lists })
  end

  def render_list slug
    years = {}
    AWS::S3::Bucket.keylist('listlibrary_cachedhash', "render/month/#{slug}/").each do |key|
      render_month = AWS::S3::S3Object.load_yaml(key, "listlibrary_cachedhash")
      year, month = key.split('/')[3..-1]
      years[year] ||= {}
      years[year][month] = { :threads => render_month.length, :messages => render_month.collect { |t| t[:messages] }.sum }
    end
    CachedHash.new('render/index')[slug] = '' unless AWS::S3::S3Object.exists?("render/index/#{slug}", 'listlibrary_cachedhash')
    html = View::render(:page => "list", :locals => {
      :title     => slug,
      :years     => years,
      :list      => List.new(slug),
      :slug      => slug,
    })
    @rc.upload_file "#{slug}/index.html", html
    html
  end

  def month_previous_next(slug, year, month)
    render_month = CachedHash.new("render/month/#{slug}")

    p = Time.utc(year, month).plus_month(-1)
    p_month = "%02d" % p.month
    if render_month["#{p.year}/#{p_month}"]
      p_link = "<a href=\"/#{slug}/#{p.year}/#{p_month}\">#{p.year}-#{p_month}</a>"
    else
      p_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    n = Time.utc(year, month).plus_month(1)
    n_month = "%02d" % n.month
    if render_month["#{n.year}/#{n_month}"]
      n_link = "<a href=\"/#{slug}/#{n.year}/#{n_month}\">#{n.year}-#{n_month}</a>"
    else
      n_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    return [p_link, n_link]
  end

  def render_month slug, year, month
    previous_link, next_link = month_previous_next(slug, year, month)
    if render_month = AWS::S3::S3Object.load_yaml("render/month/#{slug}/#{year}/#{month}", "listlibrary_cachedhash")
      inventory = { :threads => render_month.length, :messages => render_month.collect { |t| t[:messages] }.sum }
    else
      inventory = nil
    end
    html = View::render(:page => "month", :locals => {
      :title         => "#{slug} #{year}-#{month}",
      :threadset     => ThreadSet.month(slug, year, month),
      :inventory     => inventory,
      :previous_link => previous_link,
      :next_link     => next_link,
      :list          => List.new(slug),
      :slug          => slug,
      :year          => year,
      :month         => month,
    })
    @rc.upload_file "#{slug}/#{year}/#{month}/index.html", html
    html
  end

  def thread_previous_next(slug, year, month, call_number)
    render_month = CachedHash.new("render/month/#{slug}")
    threads = YAML::load(render_month["#{year}/#{month}"])
    index = nil
    threads.each_with_index { |thread, i| index = i if thread[:call_number] == call_number }
    return ["<a class=\"none\" href=\"/#{slug}\">archive</a>", "<a class=\"none\" href=\"/#{slug}\">archive</a>"] if index.nil?

    if index == 0
      p = Time.utc(year, month).plus_month(-1)
      p_month = "%02d" % p.month
      if tl = render_month["#{p.year}/#{p_month}"]
        tl = YAML::load(tl)
        call_number, subject = tl.last[:call_number], tl.last[:subject]
        p_link = "&lt; <a href=\"/#{slug}/#{p.year}/#{p_month}/#{call_number}\">#{View::h(subject)}</a><br />#{p.year}-#{p_month}"
      else
        p_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
      end
    else
      p_index = index - 1
      call_number, subject = threads[p_index][:call_number], threads[p_index][:subject]
      p_link = "&lt; <a href=\"/#{slug}/#{year}/#{month}/#{call_number}\">#{View::h(subject)}</a>"
    end

    n_index = index + 1
    if threads[n_index]
      call_number, subject = threads[n_index][:call_number], threads[n_index][:subject]
      n_link = "<a href=\"/#{slug}/#{year}/#{month}/#{call_number}\">#{View::h(subject)}</a> &gt;"
    else
      n = Time.utc(year, month).plus_month(1)
      n_month = "%02d" % n.month
      if tl = render_month["#{n.year}/#{n_month}"]
        tl = YAML::load(tl)
        call_number, subject = tl.first[:call_number], tl.first[:subject]
        n_link = "<a href=\"/#{slug}/#{n.year}/#{n_month}/#{call_number}\">#{View::h(subject)}</a> &gt;<br />#{n.year}-#{n_month}"
      else
        n_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
      end
    end

    return [p_link, n_link]
  end

  def render_thread slug, year, month, call_number
    previous_link, next_link = thread_previous_next(slug, year, month, call_number)
    thread = AWS::S3::S3Object.load_yaml("list/#{slug}/thread/#{year}/#{month}/#{call_number}")
    html = View::render :page => "thread", :locals => {
      :title         => "#{thread.n_subject} (#{slug} #{year}-#{month})",
      :thread        => thread,
      :previous_link => previous_link,
      :next_link     => next_link,
      :list          => List.new(slug),
      :slug          => slug,
      :year          => year,
      :month         => month,
    }
    @rc.upload_file "#{slug}/#{year}/#{month}/#{call_number}", html
    html
  end

  def delete_thread slug, year, month, call_number
    @rc.command("/bin/rm -f listlibrary.net/#{slug}/#{year}/#{month}/#{call_number}")
    nil
  end

  def get_job
    if @jobs.empty?
      if @stop_on_empty
        @rc.close
        exit
      end
      @jobs = AWS::S3::Bucket.objects('listlibrary_cachedhash', :reload => true, :prefix => 'render_queue/')
    end
    @jobs.pop
  end

  def run
    render_queue = CachedHash.new("render_queue")

    while job = get_job
      slug, year, month, call_number = job.key.split('/')[1..-1]
      $stdout.puts [slug, year, month, call_number].compact.join('/')
      job.delete
      render_static && next if slug == '_static'

      if call_number # render/delete a thread
        if AWS::S3::S3Object.exists? "list/#{slug}/thread/#{year}/#{month}/#{call_number}", "listlibrary_archive"
          render_thread slug, year, month, call_number
        else
          delete_thread slug, year, month, call_number
        end
        render_queue["#{slug}/#{year}/#{month}"] = ''
      elsif year and month # render monthly thread list
        render_month slug, year, month
        render_queue["#{slug}"] = ''
      else # render list info page
        render_list  slug
      end
    end
  end
end

if __FILE__ == $0
  r = Renderer.new
  ARGV.each do |job|
    r.stop_on_empty = true
    AWS::S3::S3Object.delete("render_queue/#{job}", 'listlibrary_cachedhash')
    r.jobs << OpenStruct.new(:key => "render_queue/#{job}", :delete => nil)
  end
  r.run
end
