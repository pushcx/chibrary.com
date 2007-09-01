require 'time'
require 'md5'
require 'aws'

class Message
  attr_reader   :message, :call_number, :source
  attr_accessor :addresses, :overwrite

  RE_PATTERN = /\s*\[?(Re|Fwd)([\[\(]?\d+[\]\)]?)?:\s*/i
  def self.subject_is_reply? s ; !!(s =~ RE_PATTERN)    ; end
  def self.normalize_subject s ; s.gsub(RE_PATTERN, '') ; end

  def initialize message, source=nil, call_number=nil
    @addresses = CachedHash.new "list_address"

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
    date # If date is missing/broken, set it to Time.now
  end

  def id ; message_id ; end

  def body
    message.split(/\n\r?\n/)[1..-1].join("\n\n").tr("\r", '').strip
  end

  def headers
    message.split(/\n\r?\n/)[0]
  end

  def get_header header
    match = /^#{header}:\s*(.*?)^\S/mi.match(headers + "\n.")
    return nil if match.nil?
    # take first match so that lines we add_header'd take precedence
    match.captures.shift.sub(/(\s)+/, ' ').sub(/\n[ \t]+/m, " ").strip
  end

  def from
    (get_header('From') or '').sub(/"(.*?)"/, '\1')
  end

  def date
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
    date
  end

  def subject
    get_header('Subject') or ''
  end

  def references
    in_reply_to = (get_header('In-Reply-To') or '').split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.first
    references = (get_header('References') or '').split(/[^\w@\.\-]/).select { |s| s =~ /@/ }
    references << in_reply_to unless in_reply_to.nil? or references.include? in_reply_to
    references
  end

  def no_archive?
    !!(/yes/i =~ get_header('X-No-Archive'))
  end

  def mailing_list
    matches = nil
    [ /^X-Mailing-List:\s.*/,
      /^To:\s.*/, /^C[cC]:\s.*/,
      /^B[cC][cC]:\s.*/,
      /^Reply-[Tt]o:\s.*/,
      /^List-[Pp]ost:\s.*/,
      /^Mail-[Ff]ollowup-[Tt]o:\s.*/,
      /Mail-[Rr]eply-[Tt]o:\s.*/
    ].each do |regexp|
      matches = regexp.match(headers)
      break unless matches.nil?
    end
    return "_listlibrary_no_list" if matches.nil?

    slug = nil
    matches[0].chomp.split(/[^\w@\.\-_]/).select { |s| s =~ /@/ }.each do |address|
      slug = @addresses[address]
      break unless slug.nil?
    end

    slug ||= "_listlibrary_no_list"
  end

  def generated_id
    "#{call_number}@generated-message-id.listlibrary.net"
  end

  def add_header(header)
    name = header.match(/^(.+?):\s/).captures.shift
    new_headers = "#{header.chomp}\n"
    new_headers += "X-ListLibrary-Added-Header: #{name}\n" unless name.match(/^X-ListLibrary-/)
    @message = new_headers + message
  end

  def message_id
    begin
      /^Message-[Ii][dD]:\s*<?(.*)>/.match(headers)[1].chomp
    rescue
      add_header "Message-Id: <#{generated_id}>"
      message_id
    end
  end

  def filename
    "list/#{mailing_list}/message/#{date.year}/%02d/" % date.month + message_id
  end

  def store
    unless @overwrite
      raise "overwrite attempted for listlibrary_archive #{filename}" if AWS::S3::S3Object.exists?(filename, "listlibrary_archive")
    end
    AWS::S3::S3Object.store(filename, message, "listlibrary_archive", {
      :content_type             => "text/plain",
      :'x-amz-meta-source'      => @source,
      :'x-amz-meta-call_number' => call_number
    })
    self
  end
end
