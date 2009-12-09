class MonthController < ApplicationController
  before_filter :load_list, :load_month
  caches_page :show

  def show
    @title = "#{@list['name'] or @slug} #{@year}-#{@month} archive"
    @message_count = @list.thread_list(@year, @month).message_count
    raise ActionController::RoutingError, "No messages in #{@slug}/#{@year}/#{@month}" if @message_count == 0
    @previous_link, @next_link = month_previous_next(@slug, @year, @month)
    @threadset = ThreadSet.month(@slug, @year, @month)
  end

  private

  def month_previous_next(slug, year, month)
    list = List.new(slug)

    p = Time.utc(year, month).plus_month(-1)
    p_month = "%02d" % p.month
    if list.thread_list(p.year, p_month).message_count > 0
      p_link = "<a href=\"/#{slug}/#{p.year}/#{p_month}\">#{p.year}-#{p_month}</a>"
    else
      p_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    n = Time.utc(year, month).plus_month(1)
    n_month = "%02d" % n.month
    if list.thread_list(n.year, n_month).message_count > 0
      n_link = "<a href=\"/#{slug}/#{n.year}/#{n_month}\">#{n.year}-#{n_month}</a>"
    else
      n_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
    end

    return [p_link, n_link]
  end
end
