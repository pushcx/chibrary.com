#!/usr/bin/ruby

require 'rubygems'
require 'ostruct'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'queue'
require 'stdlib'
require 'list'
require 'log'
require 'remote_connection'
require 'view'

class Renderer
  attr_accessor :jobs, :stop_on_empty

  def initialize
    @thread_q = Queue.new :render_thread
    @month_q  = Queue.new :render_month
    @list_q   = Queue.new :render_list
    @static_q = Queue.new :render_static
    @rc = RemoteConnection.new
  end

  def render_static
    %w{about search error/403 error/404}.each do |page|
      @rc.upload_file page, View::render(:page => page)
    end

    lists = []
    $archive['render/index'].each do |key|
      lists << List.new(key.split('/')[-1])
    end
    @rc.upload_file 'index', View::render(:page => 'index', :locals => { :lists => lists })
  end

  def render_list slug
    list = List.new(slug)
    years = list.year_counts

    html = View::render(:page => "list", :locals => {
      :title     => slug,
      :years     => years,
      :list      => list,
      :slug      => slug,
    })
    @rc.upload_file "#{slug}/index.html", html
    html
  end

  def month_previous_next(slug, year, month)
    list = List.new(slug)

    p = Time.utc(year, month).plus_month(-1)
    p_month = "%02d" % p.month
    if list.thread_list(p.year, p_month)
      p_link = "<a href=\"/#{slug}/#{p.year}/#{p_month}\">#{p.year}-#{p_month}</a>"
    else
      p_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    n = Time.utc(year, month).plus_month(1)
    n_month = "%02d" % n.month
    if list.thread_list(n.year, n_month)
      n_link = "<a href=\"/#{slug}/#{n.year}/#{n_month}\">#{n.year}-#{n_month}</a>"
    else
      n_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    return [p_link, n_link]
  end

  def render_month slug, year, month
    list = List.new(slug)
    previous_link, next_link = month_previous_next(slug, year, month)
    if thread_list = list.thread_list(year, month)
      message_count = thread_list.collect { |t| t[:messages] }.sum
    else
      message_count = nil
    end
    html = View::render(:page => "month", :locals => {
      :title         => "#{slug} #{year}-#{month}",
      :threadset     => ThreadSet.month(slug, year, month),
      :message_count => message_count,
      :previous_link => previous_link,
      :next_link     => next_link,
      :list          => list,
      :slug          => slug,
      :year          => year,
      :month         => month,
    })
    @rc.upload_file "#{slug}/#{year}/#{month}/index.html", html
    html
  end

  def thread_previous_next(slug, year, month, call_number)
    list = List.new(slug)
    index = nil
    threads = list.thread_list year, month
    threads.each_with_index { |thread, i| index = i if thread[:call_number] == call_number }
    return ["<a class=\"none\" href=\"/#{slug}\">archive</a>", "<a class=\"none\" href=\"/#{slug}\">archive</a>"] if index.nil?

    # first thread in a month should link to last thread of previous month
    if index == 0
      p = Time.utc(year, month).plus_month(-1)
      p_month = "%02d" % p.month
      # if there's a thread_list for the previous month, link to its last message
      if tl = list.thread_list(p.year, p_month)
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

    # if there's a next thread, link it
    n_index = index + 1
    if threads[n_index]
      call_number, subject = threads[n_index][:call_number], threads[n_index][:subject]
      n_link = "<a href=\"/#{slug}/#{year}/#{month}/#{call_number}\">#{View::h(subject)}</a> &gt;"
    else
      # otherwise, link to first thread of next month's thread_list
      n = Time.utc(year, month).plus_month(1)
      n_month = "%02d" % n.month
      if tl = list.thread_list(n.year, n_month)
        call_number, subject = tl.first[:call_number], tl.first[:subject]
        n_link = "<a href=\"/#{slug}/#{n.year}/#{n_month}/#{call_number}\">#{View::h(subject)}</a> &gt;<br />#{n.year}-#{n_month}"
      else
        n_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
      end
    end

    return [p_link, n_link]
  end

  def render_thread slug, year, month, call_number
    list = List.new(slug)
    thread = list.thread year, month, call_number
    previous_link, next_link = thread_previous_next(slug, year, month, call_number)
    html = View::render :page => "thread", :locals => {
      :title         => "#{thread.n_subject} (#{slug} #{year}-#{month})",
      :thread        => thread,
      :previous_link => previous_link,
      :next_link     => next_link,
      :list          => list,
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
    @thread_q.next or @month_q.next or @list_q.next or @static_q.next
  end

  def run
    log = Log.new "Renderer"
    log.block "renderer" do |log|
    while job = get_job
      log.block job.key, job.type do |log|
      case job.type
      when :render_thread
        if $archive.has_key? "list/#{job[:slug]}/thread/#{job[:year]}/#{job[:month]}/#{job[:call_number]}"
          render_thread job[:slug], job[:year], job[:month], job[:call_number]
        else
          delete_thread job[:slug], job[:year], job[:month], job[:call_number]
        end
      when :render_month
        render_month job[:slug], job[:year], job[:month]
      when :render_list
        render_list job[:slug]
      when :render_static
        render_static
      else
        raise log.error("Unknown job type: #{job.type}")
      end
      nil
      end
    end
  end
  end
end

Renderer.new.run if __FILE__ == $0
