# Require config/environment.rb
require ::File.expand_path('../config/environment',  __FILE__)

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/partial'

# these specific routes need to get loaded first so that list doesn't shadow them
require 'web/route/about_route'
require 'web/route/search_route'
# and these need to be loaded next so that month view doesn't shadow them
require 'web/route/thread_route'
require 'web/route/message_route'
Dir['web/route/**/*.rb', 'web/helper/**/*.rb'].each { |f| require f }

before do
  @title = "Chibrary - Free Mailing List Archives"
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end


set :app_file, __FILE__
set :haml, format: :html5, layout: :'layout/application.html'

configure do
  set :views, 'web/view'
  set :public_folder, 'web/public'
end

run Sinatra::Application
