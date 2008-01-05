require 'net/http'
require 'uri'

require 'cachedhash'

KEY = "r'sxs2l_}jnwrlyoxclz\\iivzmlykCnvkdhuonhemk+Rah6nrn\"%qbvqt/lb"

class Log
  def self.<< message
    @@server ||= CachedHash.new("server")[`hostname`.chomp]
    response = Net::HTTP.post_form(URI.parse('http://dynamic.listlibrary.net/log.php'), {
      'key'     => KEY,
      'server'  => @@server,
      'pid'     => Process.pid,
      'message' => message,
    })
    raise "couldn't log: #{response.body}" unless response.body == '1'
    puts message
    message
  end
end
