require 'aws'

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
  attr_accessor :mailing_lists, :print_status, :S3Object, :sequences, :threader_queue

  def initialize server=nil, sequence=nil
    # load server id and sequence number for this server and pid
    @server = (server or CachedHash.new("servers")[`hostname`].to_i)
    @sequences = CachedHash.new("sequences")
    @sequence = (sequence or @sequences["#{@server}/#{Process.pid}"].to_i)
    @threader_queue = CachedHash.new("threader_queue")

    # queue up threading workers for this mailing list, year, and month
    @mailing_lists = {}
    # count the number of messages stored
    @message_count = 0
    @print_status = true

    @S3Object = AWS::S3::S3Object
  end

  def call_number
    # call numbers are 48 binary digits. First 8 are 0 for future
    # expansion. Next 4 are server id. Next 16 # are process id.
    # Last 20 are an incremeting sequence ID.
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

  # This line is in a separate method so tests can subclass and override
  def new_message mail
    Message.new(mail, call_number)
  end

  def store mail
    return false if mail.length >= (256 * 1024)

    message = new_message mail
    @message_count += 1
    begin
      message.store
      unless message.mailing_list.match /^_/
        @mailing_lists[message.mailing_list] ||= []
        @mailing_lists[message.mailing_list] << [message.date.year, message.date.month]
      end
      puts "#{@message_count} stored at #{message.filename}" if @print_status
    rescue Exception => e
      puts "#{@message_count} failed to store: #{e.message}; failure stored as #{call_number}" if @print_status
      @S3Object.store(
        "_listlibrary_failed/#{call_number}",
        {
          :exception => e.class.to_s,
          :message   => e.message,
          :backtrace => e.backtrace,
          :mail      => message.message
        }.to_yaml,
        'listlibrary_archive',
        :content_type => "text/plain"
      )
    ensure
      release
    end

    true
  end

  def run
    # no error-catching for setup; if it fails we'll just stop
    setup
    begin
      stored = acquire { |m| store m }
      @sequence += 1 if stored
    ensure
      @sequences["#{@server}/#{Process.pid}"] = sequence
      queue_threader
      teardown
    end
  end

  def queue_threader
    @mailing_lists.each do |list, dates|
      dates.each do |year, month|
        @threader_queue[ [list, year, month].join('/') ] = ''
      end
    end
  end

end
