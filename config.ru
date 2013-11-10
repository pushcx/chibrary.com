# Require config/environment.rb
require ::File.expand_path('../config/environment',  __FILE__)

set :app_file, __FILE__

configure do
  set :views, 'web/views'
  set :public_folder, 'web/public'
end

run Sinatra::Application
