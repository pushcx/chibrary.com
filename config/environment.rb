# load all the app's libs, which do not all use constants to get autoloaded
Dir["#{RAILS_ROOT}/lib/*.rb"].each    { |l| require l }
# load all the models: YAML doesn't trigger the Rails autoloader when it's deserializing objects
Dir["#{RAILS_ROOT}/models/*.rb"].each { |l| require l }

LOG_PASSWD = "r'sxs2l_}jnwrlyoxclz\\iivzmlykCnvkdhuonhemk+Rah6nrn\"%qbvqt/lb"
LOG_STATUSES = [:begin, :end, :error, :warning, :status]
