require 'net/http'
require 'uri'

class Log
  attr_reader :worker, :key

  def initialize worker, depth=0
    @@server ||= CachedHash.new("server")[`hostname`.chomp] unless in_test_mode?
    @worker = worker
    @depth = depth
  end

  # begin/end: evil temporal coupling
  def begin key, message=nil
    @key = key
    log :begin, message
  end

  def end message=nil
    log :end, message
    @key = nil
    message
  end

  def block key, message=nil
    self.begin key, message
    msg = yield Log.new(@worker, @depth + 1)
    msg = nil unless msg.is_a? String
    self.end msg
  end

  def error message   ; log :error,   message ; end
  def warning message ; log :warning, message ; end
  def status message  ; log :status,  message ; end

  private

  def log status, message
    #response = Net::HTTP.post_form(URI.parse('http://chibrary.com/log.php'), {
    #  'passwd'  => LOG_PASSWD,
    #  'log_message' => {
    #    'server'  => @@server,
    #    'pid'     => Process.pid,
    #    'key'     => @key,
    #    'worker'  => @worker,
    #    'status'  => status,
    #    'message' => message,
    #  }
    #})
    #raise "couldn't log: #{response.body}" unless response.body == '1'
    puts '  ' * @depth + "#{@key}: #{message}"
    message
  end

  def in_test_mode? ; false ; end
end
