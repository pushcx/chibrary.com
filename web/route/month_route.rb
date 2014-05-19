get '/:slug/:year/:month/?' do
  load_list
  load_month
  sym = Sym.new(@slug, @year, @month)

  @title = "#{@list.title_name} #{@year}-#{@month} archive"
  @month_count = MonthCountRepo.find sym
  raise Sinatra::NotFound, "No messages in #{@slug}/#{@year}/#{@month}" if @month_count.empty?
  @previous_link, @next_link = month_previous_next sym
  @summary_set = SummarySetRepo.find sym

  haml :'month/show.html'
end
