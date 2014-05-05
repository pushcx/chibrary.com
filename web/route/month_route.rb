require_relative '../../value/sym'

get '/:slug/:year/:month/?' do
  load_list
  load_month

  @title = "#{@list.title_name} #{@year}-#{@month} archive"
  @month_count = MonthCountRepo.find Sym.new(@slug, @year, @month)
  raise Sinatra::NotFound, "No messages in #{@slug}/#{@year}/#{@month}" if @month_count.empty?
  @previous_link, @next_link = month_previous_next(Sym.new(@slug, @year, @month))
  @threadset = ThreadSet.month(@slug, @year, @month)

  haml :'month/show.html'
end
