get '/:slug/?' do
  load_list
  @snippets = []
  #load_list_snippets

  @title = "#{@list['name'] or @slug} archive"
  @year_counts = ThreadList.year_counts @slug

  haml :'list/show.html'
end

get  '/:slug/:year/?' do
  redirect "/#{params[:slug]}"
end
