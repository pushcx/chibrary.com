require 'time'
require 'md5'
require 'aws'

class Message
  attr_reader   :from, :message, :source, :slug # used by code
  attr_reader   :call_number, :message_id, :references, :subject, :date, :from, :no_archive, :key # for yaml
  attr_accessor :overwrite

  RE_PATTERN = /\s*\[?(Re|Fwd)([\[\(]?\d+[\]\)]?)?:\s*/i
  def self.subject_is_reply? s ; !!(s =~ RE_PATTERN)    ; end
  def self.normalize_subject s ; s.gsub(RE_PATTERN, '') ; end

  def initialize message, source=nil, call_number=nil
    @source = source
    @call_number = call_number
    if message.match "\n" # initialized with a message
      @message = message
    else                  # initialize with a url
      @overwrite = true
      o = AWS::S3::S3Object.find(message, 'listlibrary_archive')
      @message = o.value.to_s
      @call_number ||= o.metadata['call_number']
      @source ||= o.metadata['source']
    end
    raise "call_number '#{@call_number}' is invalid string" unless @call_number.instance_of? String and @call_number.length == 8
    extract_metadata
  end

  # public methods

  def body
    message.split(/\n\r?\n/)[1..-1].join("\n\n").tr("\r", '').strip
  end

  alias :id :message_id # threading code prefers this, haven't fixed it

  def store
    unless @overwrite
      raise "overwrite attempted for listlibrary_archive #{@key}" if AWS::S3::S3Object.exists?(@key, "listlibrary_archive")
    end
    AWS::S3::S3Object.store(@key, message, "listlibrary_archive", {
      :content_type             => "text/plain",
      :'x-amz-meta-source'      => @source,
      :'x-amz-meta-call_number' => call_number
    })
    self
  end

  # In threading, LLThread caches YAML messages, so we limit the serialization
  # to the fields the threader needs (@from and @no_archive for
  # view/thread_list which shouldn't need to load the whole message).
  # view/thread must actually load messages from their keys.
  def to_yaml_properties ; %w{@call_number @message_id @references @subject @date @from @no_archive @key} ; end

  private

  # header code

  def headers
    message.split(/\n\r?\n/)[0]
  end

  def add_header(header)
    name = header.match(/^(.+?):\s/).captures.shift
    new_headers = "#{header.chomp}\n"
    new_headers += "X-ListLibrary-Added-Header: #{name}\n" unless name.match(/^X-ListLibrary-/)
    @message = new_headers + message
    extract_metadata
  end

  def get_header header
    match = /^#{header}:\s*(.*?)^\S/mi.match(headers + "\n.")
    return nil if match.nil?
    # take first match so that lines we add_header'd take precedence
    match.captures.shift.sub(/(\s)+/, ' ').sub(/\n[ \t]+/m, " ").strip
  end

  # metadata code

  def extract_metadata
    load_date
    load_from
    load_message_id
    load_no_archive
    load_references
    load_slug
    load_subject

    load_key
  end

  def load_date
    date   = get_header('Date')
    begin
      date = Time.rfc2822(date).utc
    rescue
      # It's ugly to assume odd-formated dates are local time, but
      # servers will generally be running in UTC. If you can't properly
      # format an rfc2822 date, you're lucky to get anything I give you.
      begin
        date = Time.parse(date).utc
      rescue
        date = Time.now.utc
        add_header "Date: #{date.rfc2822}"
      end
    end
    @date = date
  end

  def load_key
    @key = "list/#{@slug}/message/#{date.year}/%02d/" % @date.month + @message_id
  end

  def load_from
    @from = (get_header('From') or '').sub(/"(.*?)"/, '\1')
  end

  def load_message_id
    @message_id = begin
      /^Message-[Ii][dD]:\s*<?(.*)>/.match(headers)[1].chomp
    rescue
      add_header "Message-Id: <#{call_number}@generated-message-id.listlibrary.net>"
      message_id
    end
  end

  def load_no_archive
    @no_archive = !!(
      get_header('X-No-Archive') =~ /yes/i or
      !get_header('X-Archive').nil? or
      get_header('Archive') =~ /no/i
    )
  end

  def load_references
    in_reply_to = (get_header('In-Reply-To') or '').split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.first
    references = (get_header('References') or '').split(/[^\w@\.\-]/).select { |s| s =~ /@/ }
    references << in_reply_to unless in_reply_to.nil? or references.include? in_reply_to
    @references = references
  end

  def load_slug
    @addresses = CachedHash.new "list_address"

    header = nil
    %w{
      X-Mailing-List
      List-Post
      To Cc Reply-To Bcc 
      Mail-Followup-To Mail-Reply-To
    }.each do |h|
      header = get_header(h)
      break unless header.nil?
    end
    return "_listlibrary_no_list" if header.nil?

    slug = nil
    header.chomp.split(/[^\w@\.\-_]/).select { |s| s =~ /@/ }.each do |address|
      slug = @addresses[address]
      break unless slug.nil?
    end

    slug ||= "_listlibrary_no_list"
    @slug = slug
  end

  def load_subject
    @subject = (get_header('Subject') or '')
  end
end
