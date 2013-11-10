get '/' do
  @lists = []
  $riak.list('list').each do |slug|
    @lists << List.new(slug) if $riak.has_key? "list/#{slug}/thread" and not slug =~ /^_/
  end

  @snippets = []
  #$riak.list('snippet/homepage').each_with_index { |key, i| @snippets << $riak["snippet/homepage/#{key}"] ; break if i >= 30 }
  haml :'generic/homepage.html'
end

get '/about' do
  haml :'generic/about.html'
end

get '/search' do
  haml :'generic/search.html'
end
