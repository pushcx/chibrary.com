get '/:slug/?' do
  load_list
  @snippets = []
  #load_list_snippets

  @title = "#{@list.title_name} archive"
  @years_of_month_counts = MonthCountRepo.years_of_month_counts @slug

  haml :'list/show.html'
end

get  '/:slug/:year/?' do
  redirect "/#{params[:slug]}"
end
