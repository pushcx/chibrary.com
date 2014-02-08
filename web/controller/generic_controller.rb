get '/' do
  @lists = ListStorage.all

  @snippets = []
  #$riak.list('snippet/homepage').each_with_index { |key, i| @snippets << $riak[key] ; break if i >= 30 }

  haml :'generic/homepage.html'
end

get '/about' do
  haml :'generic/about.html'
end

get '/search' do
  haml :'generic/search.html'
end
