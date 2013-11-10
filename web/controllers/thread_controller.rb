class ThreadController < ApplicationController
  #before_filter :load_list, :load_month, :load_thread

  def show
    @title = "#{subject(@thread.subject)} - #{@list['name'] or @slug}"
    @previous_link, @next_link = thread_previous_next(@slug, @year, @month, @call_number)
  end

  private
  def load_thread
    @call_number = params[:call_number]
    raise ActionController::RoutingError, "Invalid call_number" unless @call_number =~ /^[A-Za-z0-9\-_]{8}$/
    begin
      r = ThreadList.new(@slug, @year, @month).redirect? @call_number
      redirect_to "#{r}#m-#{@call_number.to_base_36}" and return if r
      @thread = $archive["list/#{@list.slug}/thread/#{@year}/#{@month}/#{@call_number}"]
    rescue NotFound
      raise ActionController::RoutingError, "Thread not found"
    end
  end

  def thread_previous_next(slug, year, month, call_number)
    def thread_link thread
      "<a href=\"/#{thread[:slug]}/#{thread[:year]}/#{thread[:month]}/#{thread[:call_number]}\">#{f(subject(thread[:subject]))}</a>"
    end
    thread_list = ThreadList.new(slug, year, month)

    if previous_thread = thread_list.previous_thread(call_number)
      previous_link = "&lt; #{thread_link(previous_thread)}"
      previous_link += "<br />#{previous_thread[:year]}-#{previous_thread[:month]}" if previous_thread[:year] != year or previous_thread[:month] != month
    else
      previous_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    if next_thread = thread_list.next_thread(call_number)
      next_link = "#{thread_link(next_thread)} &gt;"
      next_link += "<br />#{next_thread[:year]}-#{next_thread[:month]}" if next_thread[:year] != year or next_thread[:month] != month
    else
      next_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    [previous_link, next_link]
  end
end
