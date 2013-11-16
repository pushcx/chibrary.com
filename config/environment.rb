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

require 'config/routes'

# bring up the web stack
require 'web/controllers/application_controller'
Dir['web/controllers/*.rb', 'web/helpers/*.rb'].each { |file| require file }

# load all the app's libs, which do not all use constants to get autoloaded
Dir["lib/*.rb"].each    { |l| require l }
# load all the models: YAML doesn't trigger the Rails autoloader when it's deserializing objects
Dir["model/*.rb"].each { |l| require l }

LOG_PASSWD = "r'sxs2l_}jnwrlyoxclz\\iivzmlykCnvkdhuonhemk+Rah6nrn\"%qbvqt/lb"
LOG_STATUSES = [:begin, :end, :error, :warning, :status]
