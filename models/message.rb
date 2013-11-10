require 'rmail'

require 'base64'
require 'iconv'
require 'time'

class Message
  attr_reader   :from, :message, :source, :slug, :call_number, :message_id
  attr_reader   :references, :subject, :n_subject, :date, :no_archive, :key
  attr_accessor :overwrite

  RE_PATTERN = /\s*\[?(Re|Fwd?)([\[\(]?\d+[\]\)]?)?:\s*/i
  def self.normalize_subject s
    encoded_word(s).gsub(RE_PATTERN, '').strip
  end

  def self.deserialize hash
    self.new hash['message'], hash['source'], hash['call_number']
  end

  def initialize message, source=nil, call_number=nil
    @source = source
    @call_number = call_number
    @overwrite = :error
    
    if message.is_a?(String) and message.match("\n") # initialized with a raw mail
      @message = message
    else
      @overwrite = :do
      if message.is_a? String # initialized with a url
        m = $riak[message]
      elsif message.is_a? Message
        m = message
      else
        raise "Can't build Message from a #{message.class}"
      end

      @message = m.message
      @call_number ||= m.call_number
      @source ||= m.source
    end
    raise "call_number '#{@call_number}' is invalid string" unless @call_number.instance_of? String and @call_number.length == 8
    extract_metadata
  end

  def == other
    other.message == @message and other.source == @source and other.call_number == @call_number
  end

  # public methods

  def body
    return @body if @body
    return '' if @message.nil? # body is not serialized

    # Hack: use the RMail lib to find MIME-encoded body, which can be nested inside a MIME enclosure
    rmail = RMail::Parser.read(@message.gsub("\r", ''))
    parts = [rmail]
    encoding = nil
    while part = parts.shift
      if part.multipart?
        part.each_part { |p| parts << p }
        next
      end
      # content type is nil for very plain messages, or text/plain for proper ones
      content_type = part.header['Content-Type']
      charset = content_type.match(/charset="?(\S+)"?/).captures.first if content_type and content_type =~ /charset="?(\S+)"?/
      if content_type.nil? or content_type.downcase.include? 'text/plain'
        encoding = part.header['Content-Transfer-Encoding']
        @body = part.body
        break
      end
    end

    if @body.nil? # didn't find a text/plain body
      @body = "This MIME-encoded message did not include a plain text body or could not be decoded."
    end

    case encoding
    when /quoted-printable/i
      @body = @body.unpack('M').first
    when /base64/i
      @body = @body.unpack('m').first
    end # else it's fine

    @body = Message::charset_convert(charset, @body) if charset

    return @body = @body.strip
  end
  def subject_is_reply?
    !!(@subject =~ RE_PATTERN)
  end

  # Guess if this message actually starts a new thread instead of replying to parent
  def likely_lazy_reply_to? parent
    return false if n_subject == parent.n_subject # didn't change subject, almost certainly a reply
    return false if body =~ /^[>\|] .+/                # quoted something to reply to it

    # from and subject are especially important
    m_counts = {}
    (@subject.to_s * 2 + get_header('To').to_s * 2 + body.to_s).split(/\s+/).each { |word| m_counts[word] = m_counts.fetch(word, 0) + 1 if word.length > 6 }
    m_top_words = m_counts.sort_by { |word, count| count }.reverse[0..10]
    p_counts = {}
    (parent.subject.to_s * 2 + parent.from.to_s * 2 + parent.body.to_s).split(/\s+/).each { |word| p_counts[word] = p_counts.fetch(word, 0) + 1 if word.length > 6 }
    p_top_words = p_counts.sort_by { |word, count| count }.reverse[0..20]
    similar = 0
    m_top_words.each do |word|
      similar += 1 if p_top_words.include? word
      return false if similar > 6
    end
    return true
  end

  def slug= s
    @slug = s
    load_key
  end

  def store
    unless @overwrite == :do
      attempted = $riak.has_key? @key
      return self if attempted and @overwrite == :dont
      if @overwrite == :new
        generate_message_id
        load_key
      else
        raise "overwrite attempted for listlibrary_archive #{@key}" if attempted and @overwrite == :error
      end
    end
    $riak[@key] = self.to_hash
    self
  end

  def to_yaml_properties ; %w{@source @call_number @message_id @references @subject @date @from @no_archive @key @slug @message} ; end
  def to_hash
    Hash[
      %w{class source call_number message_id references subject date from no_archive key slug message}.map do |key|
        [key, self.send(key)]
      end
    ]
  end

  # method rather than var so that unserialized Messages don't have to save both
  def n_subject
    Message.normalize_subject @subject
  end

  private

  def self.charset_convert charset, text
    begin
      Iconv.conv('utf-8', charset, text)
    rescue Iconv::InvalidEncoding, Iconv::IllegalSequence, Iconv::InvalidCharacter
      text
    end
  end

  def self.encoded_word str
    str.gsub(/=\?[^\?]+\?[^\?]+\?[^\?]+\?=/) do |encoded|
      charset, encoding, text = *encoded.match(/=\?([^\?]+)\?([^\?]+)\?([^\?]+)\?=/).captures
      if encoding == 'B'
        text = text.unpack('m').first
      elsif encoding == 'Q'
        text = text.unpack('M').first
      end
      charset_convert(charset, text)
    end
  end

  # header code

  def headers
    return '' if message.nil?
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

  def generate_message_id
    @message_id = "#{call_number}@generated-message-id.listlibrary.net"
    add_header "Message-Id: <#{@message_id}>"
    load_key
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
    @key = "list/#{@slug}/message/#{@date.year}/%02d/" % @date.month + @message_id
  end

  def load_from
    @from = Message::encoded_word((get_header('From') or '').sub(/"(.*?)"/, '\1'))
  end

  def load_message_id
    if message_id = get_header('Message-Id') and message_id =~ /^<?[a-zA-Z0-9%+\-\.=_]+@[a-zA-Z0-9_\-\.]+>?$/ and message_id.length < 120
      @message_id = /^<?([^@]+@[^\>]+)>?/.match(message_id)[1].chomp
    else
      generate_message_id
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
    references << in_reply_to unless in_reply_to.nil?
    references.uniq!
    @references = references
  end

  def load_slug
    @addresses = CachedHash.new "list_address"

    headers = %w{
      X-Mailing-List List-ID X-ML-Name
      List-Post List-Owner
      To Cc Reply-To Bcc 
      Mail-Followup-To Mail-Reply-To
      Resent-To Resent-Cc Resent-Reply-To Resent-Bcc
    }.collect { |h| get_header(h) }.compact
    return "_listlibrary_no_list" if headers.empty?

    slug = nil
    headers.each do |header|
      header.chomp.split(/[^\w@\.\-_]/).select { |s| s =~ /@/ }.each do |address|
        slug = @addresses[address]
        break unless slug.nil?
      end
      break unless slug.nil?
    end

    slug ||= "_listlibrary_no_list"
    @slug = slug
  end

  def load_subject
    @subject = (get_header('Subject') or '')
  end
end
