get '/:slug/:year/:month/?' do
  load_list
  load_month

  @title = "#{@list.title_name} #{@year}-#{@month} archive"
  @year_of_month_counts = MonthCountStorage.year_of_month_counts @slug, @year
  @month_count = @year_of_month_counts[@month]
  raise ActionController::RoutingError, "No messages in #{@slug}/#{@year}/#{@month}" if @month_count.nil?
  @previous_link, @next_link = month_previous_next(@slug, @year, @month)
  @threadset = ThreadSet.month(@slug, @year, @month)

  haml :'month/show.html'
end
