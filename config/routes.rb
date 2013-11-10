#ActionController::Routing::Routes.draw do |map|
#  map.resources :log_messages
#
#
#  map.connect 'about',  :controller => 'generic', :action => 'about'
#  map.connect '',       :controller => 'generic', :action => 'homepage'
#  map.connect 'search', :controller => 'generic', :action => 'search'
#
#  map.resources :flags, :only => [ :create ]
#  map.resources :log, :only => [ :create ]
#
#  map.connect ':slug',                           :controller => 'list',   :action => 'show'
#  map.connect ':slug/:year',                     :controller => 'list',   :action => 'year_redirect'
#  map.connect ':slug/:year/:month',              :controller => 'month',  :action => 'show'
#  map.connect ':slug/:year/:month/:call_number', :controller => 'thread', :action => 'show'
#end

before do
  @title = "ListLibrary.net - Free Mailing List Archives"
end

get '/about' do
  haml :'generic/about.html'
end

get '/search' do
  haml :'generic/search.html'
end
