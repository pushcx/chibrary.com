# Require config/environment.rb
require ::File.expand_path('../config/environment',  __FILE__)

set :app_file, __FILE__
set :haml, format: :html5, layout: :'layouts/application.html'

configure do
  set :views, 'web/views'
  set :public_folder, 'web/public'
end

run Sinatra::Application
