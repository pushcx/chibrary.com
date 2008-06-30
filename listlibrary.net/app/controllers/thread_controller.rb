class ThreadController < ApplicationController
  before_filter :load_list, :load_month, :load_thread

  def show
    @previous_link, @next_link = thread_previous_next(@slug, @year, @month, @call_number)
  end

  private
  def load_thread
    @call_number = params[:call_number]
    raise ActionController::RoutingError, "Invalid call_number" unless @call_number =~ /^[A-Za-z0-9\-_]{8}$/
    begin
      @thread = $archive["list/#{@list.slug}/thread/#{@year}/#{@month}/#{@call_number}"]
    rescue NotFound
      raise ActionController::RoutingError, "Thread not found"
    end
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
        p_link = "&lt; <a href=\"/#{slug}/#{p.year}/#{p_month}/#{call_number}\">#{f(subject)}</a><br />#{p.year}-#{p_month}"
      else
        p_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
      end
    else
      p_index = index - 1
      call_number, subject = threads[p_index][:call_number], threads[p_index][:subject]
      p_link = "&lt; <a href=\"/#{slug}/#{year}/#{month}/#{call_number}\">#{f(subject)}</a>"
    end

    # if there's a next thread, link it
    n_index = index + 1
    if threads[n_index]
      call_number, subject = threads[n_index][:call_number], threads[n_index][:subject]
      n_link = "<a href=\"/#{slug}/#{year}/#{month}/#{call_number}\">#{f(subject)}</a> &gt;"
    else
      # otherwise, link to first thread of next month's thread_list
      n = Time.utc(year, month).plus_month(1)
      n_month = "%02d" % n.month
      if tl = list.thread_list(n.year, n_month)
        call_number, subject = tl.first[:call_number], tl.first[:subject]
        n_link = "<a href=\"/#{slug}/#{n.year}/#{n_month}/#{call_number}\">#{f(subject)}</a> &gt;<br />#{n.year}-#{n_month}"
      else
        n_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
      end
    end

    return [p_link, n_link]
  end
end
