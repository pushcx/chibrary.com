require 'yaml'
require 'lib/storage'
require 'lib/remote_connection'

class SequenceExhausted < RuntimeError ; end

class Integer
  def to_base_64
    raise "No negative numbers" if self < 0

    chars = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a + ['_', '-']
    str = ""
    current = self

    while current != 0
      str = chars[current % 64].to_s + str
      current = current / 64
    end
    raise "Unexpectedly large int converted" if str.length > 8
    ("%8s" % str).tr(' ', '0')
  end
end

class Filer
  attr_reader :server, :sequence, :message_count
  attr_accessor :mailing_lists, :sequences

  def initialize server=nil, sequence=nil
    # load server id and sequence number for this server and pid
    @server = (server or CachedHash.new("server")[`hostname`.chomp])
    raise "id not found or given for server #{`hostname`.chomp}" if @server.nil?
    @server = @server.to_i
    @sequences = CachedHash.new("sequence")
    @sequence = (sequence or @sequences["#{@server}/#{Process.pid}"].to_i)

    # queue up threading workers for this mailing list, year, and month
    @mailing_lists = {}
    # count the number of messages stored
    @message_count = 0
  end

  def call_number
    # call numbers are 48 binary digits. First 8 are 0 for future
    # expansion. Next 4 are server id. Next 16 # are process id.
    # Last 20 are an incremeting sequence ID.
    raise SequenceExhausted, "sequence for server #{@server}, pid #{Process.pid} exhausted" if @sequence >= 2 ** 20
    ("%04b%016b%020b" % [@server, Process.pid, @sequence]).to_i(2).to_base_64
  end

  # Stubs for subclasses to override:
  # setup and teardown are called before and after the run
  def setup    ; end
  def teardown ; end
  # acquire must yield the raw text of each new message
  def acquire  ; raise "Filer.acquire() must be overridden by subclasses" ; end
  # hook if anything needs to be done to clean up after store
  def release  ; end
  def source   ; 'filer' ; end
  # define this to force a slug; handy for mailing list imports
  def slug     ; nil ; end

  def store mail, overwrite=nil
    return false if mail.is_a? String and mail.length >= (256 * 1024)

    @message_count += 1
    begin
      message = Message.new mail, source, call_number
      message.overwrite = overwrite if overwrite
      message.slug = slug unless slug.nil?
      message.store
      unless message.slug.match /^_/
        @mailing_lists[message.slug] ||= []
        pair = [message.date.year, message.date.month]
        @mailing_lists[message.slug] << pair unless @mailing_lists[message.slug].include? pair
      end
      $stdout.puts "#{@message_count} #{call_number} stored: #{message.key}"
    rescue SequenceExhausted
      raise
    rescue Exception => e
      begin
        $stdout.puts "#{@message_count} #{call_number} FAILED: #{e.message}"
        error_info = {
          :exception => e.class.to_s,
          :message   => e.message,
          :backtrace => e.backtrace,
          :mail      => mail
        }
        $archive["filer_failure/#{call_number}"] = error_info
      rescue
        $stdout.puts "#{@message_count} #{call_number} DOUBLE FAILURE: #{e.message}"
        secondary_error_info = {
          :exception => e.class.to_s,
          :message   => e.message,
          :backtrace => e.backtrace
        }.to_yaml
        # double failure: couldn't store the failure in s3
        @rc ||= RemoteConnection.new
        @rc.upload_file "filer_double_failure/#{call_number}", [secondary_error_info, error_info].to_yaml
      end
    ensure
      release
      @sequence += 1
    end
    true
  end

  def run
    # no error-catching for setup; if it fails we'll just stop
    setup
    begin
      acquire { |message, overwrite| store message, overwrite }
    ensure
      @sequences["#{@server}/#{Process.pid}"] = @sequence
      queue_threader
      teardown
    end
    return @message_count
  end

  def queue_threader
    @thread_q = Queue.new :thread
    @mailing_lists.each do |slug, dates|
      dates.each do |year, month|
        @thread_q.add :slug => slug, :year => year, :month => "%02d" % month
      end
    end
  end
end
