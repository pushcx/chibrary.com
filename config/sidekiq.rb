# Set up gems listed in the Gemfile.
# See: http://gembundler.com/bundler_setup.html
#      http://stackoverflow.com/questions/7243486/why-do-you-need-require-bundler-setup
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
$LOAD_PATH << File.expand_path('../../', __FILE__)
require 'rubygems'
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis.example.com:6379/0', namespace: 'sidekiq' }
end
Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis.example.com:6379/0', namespace: 'sidekiq', size: 1 }
end

Dir["lib/**/*.rb", 'model/**/*.rb'].each { |l| require l }

Dir["worker/**/*.rb"].each { |l| require l }
