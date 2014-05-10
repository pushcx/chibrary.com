# Set up gems listed in the Gemfile.
# See: http://gembundler.com/bundler_setup.html
#      http://stackoverflow.com/questions/7243486/why-do-you-need-require-bundler-setup
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
$LOAD_PATH << File.expand_path('../../', __FILE__)
require 'rubygems'
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/partial'

require 'logger'
require 'pathname'

# Some helper constants for path-centric logic
APP_ROOT = Pathname.new(__FILE__)
APP_NAME = 'chibrary'

Dir["lib/**/*.rb", 'value/**/*.rb', 'model/**/*.rb', 'repo/**/*.rb'].each { |f| require f }

# finally, bring up the web stack
Dir['web/route/**/*.rb', 'web/helper/**/*.rb'].each { |file| require file }

before do
  @title = "Chibrary - Free Mailing List Archives"
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

