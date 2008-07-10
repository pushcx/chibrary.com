class MonthController < ApplicationController
  before_filter :load_list, :load_month
  caches_page :show

  def show
    @previous_link, @next_link = month_previous_next(@slug, @year, @month)
    if @thread_list = @list.thread_list(@year, @month)
      @message_count = @thread_list.collect { |t| t[:messages] }.sum
    else
      @message_count = nil
    end
    @threadset = ThreadSet.month(@slug, @year, @month)
  end

  private
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
end
