get '/:slug/:year/:month/?' do
  load_list
  load_month

  @title = "#{@list.title_name} #{@sym.year}-#{@sym.month} archive"
  @month_count = MonthCountRepo.find @sym
  raise Sinatra::NotFound, "No messages in #{@sym.to_key}" if @month_count.empty?
  @previous_link, @next_link = month_previous_next @sym
  @threads = ThreadRepo.month @sym

  haml :'month/show.html'
end
