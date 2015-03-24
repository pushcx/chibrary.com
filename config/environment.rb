# Set up gems listed in the Gemfile.
# See: http://gembundler.com/bundler_setup.html
#      http://stackoverflow.com/questions/7243486/why-do-you-need-require-bundler-setup
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
$LOAD_PATH << File.expand_path('../../', __FILE__)
require 'rubygems'
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# Some helper constants for path-centric logic
Dir["lib/**/*.rb", 'value/**/*.rb', 'entity/**/*.rb', 'repo/**/*.rb', 'worker/**/*.rb'].each { |f| require f }
include Chibrary
