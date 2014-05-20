# Require config/environment.rb
require ::File.expand_path('../config/environment',  __FILE__)

set :app_file, __FILE__
set :haml, format: :html5, layout: :'layout/application.html', escape_html: true

configure do
  set :views, 'web/view'
  set :public_folder, 'web/public'
end

run Sinatra::Application
