# Log queries to STDOUT in development
if Object.const_defined? 'ActiveRecord' and Sinatra::Application.development?
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

# Heroku hassle; add uri gem
#db = URI.parse(ENV['DATABASE_URL'] || "postgres://localhost/#{APP_NAME}_#{Sinatra::Application.environment}")

# Note:
#   Sinatra::Application.environment is set to the value of ENV['RACK_ENV']
#   if ENV['RACK_ENV'] is set.  If ENV['RACK_ENV'] is not set, it defaults
#   to :development

#ActiveRecord::Base.establish_connection(
#  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
#  :host     => db.host,
#  :port     => db.port,
#  :username => db.user,
#  :password => db.password,
#  :database => APP_NAME,
#  :encoding => 'utf8'
#)
