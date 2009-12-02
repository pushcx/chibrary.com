ActionController::Routing::Routes.draw do |map|
  map.connect 'about',  :controller => 'generic', :action => 'about'
  map.connect '',       :controller => 'generic', :action => 'homepage'
  map.connect 'search', :controller => 'generic', :action => 'search'
  
  map.connect ':slug',                           :controller => 'list',   :action => 'show'
  map.connect ':slug/:year',                     :controller => 'list',   :action => 'year_redirect'
  map.connect ':slug/:year/:month',              :controller => 'month',  :action => 'show'
  map.connect ':slug/:year/:month/:call_number', :controller => 'thread', :action => 'show'
end
