get '/:slug/:year/:month/?' do
  load_list
  load_month

  @title = "#{@list['name'] or @slug} #{@year}-#{@month} archive"
  @message_count = @list.thread_list(@year, @month).message_count
  raise ActionController::RoutingError, "No messages in #{@slug}/#{@year}/#{@month}" if @message_count == 0
  @previous_link, @next_link = month_previous_next(@slug, @year, @month)
  @threadset = ThreadSet.month(@slug, @year, @month)

  haml :'month/show.html'
end
