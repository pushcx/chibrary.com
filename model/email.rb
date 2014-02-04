require 'base64'
require 'rmail'
require 'time'

require_relative 'headers'
require_relative 'subject'
require_relative 'message_id'

class Email
  attr_reader :raw, :header
  attr_reader :from, :message_id, :references, :date, :no_archive, :subject

  extend Forwardable
  def_delegator :@subject, :normalized, :n_subject

  def initialize fields
    @raw        = fields[:raw]
    @header     = Headers.new raw.split(/\n\r?\n/).first
    @message_id = MessageId.new(fields[:message_id] || extract_message_id)
    @subject    = Subject.new(fields[:subject] || extract_subject)
    @from       = fields[:from]       || extract_from
    @references = fields[:references] || extract_references
    @date       = fields[:date]       || extract_date
    @no_archive = fields[:no_archive] || extract_no_archive
  end

  def extract_message_id
    header['Message-Id']
  end

  def extract_subject
    header['Subject']
  end

  def extract_from
    header['From'].sub(/"(.*?)"/, '\1').decoded
  end

  def extract_references
    "#{header['In-Reply-To']} #{header['References']}".
      split(/\s+/).
      map { |s| MessageId.new(s) }.
      select { |m| m.valid? }.
      uniq
  end

  def extract_date
    raw = header['Date']
    begin
      date = Time.rfc2822(raw).utc
    rescue
      begin
        # if it didn't manage an rfc date, hope for iso date. This is nice
        # when Emails have to be reconstructed from an archive.
        date = Time.parse(raw + " UTC").utc
      rescue
        # If it's completely fucked, well, now is as good at time as any.
        date = Time.now.utc
      end
    end
  end

  def extract_no_archive
    @no_archive = !!(
      header['X-No-Archive'] =~ /yes/i or
      header['X-Archive'] != '' or
      header['Archive'] =~ /no/i
    )
  end

  def extract_body
    return '' if raw.nil? # body is not serialized

    # Hack: use the RMail lib to find MIME-encoded body, which can be nested
    # inside a MIME enclosure. This will have to change when I move to Ruby
    # 2.0, as RMail is broken there.
    rmail = RMail::Parser.read(raw.gsub("\r", ''))
    parts = [rmail]
    encoding = nil
    while part = parts.shift
      if part.multipart?
        part.each_part { |p| parts << p }
        next
      end
      # content type is nil for very plain messages, or text/plain for proper ones
      content_type = part.header['Content-Type']
      if content_type
        match = content_type.match(/charset="?([a-zA-Z\-_0-9]+)"?/)
        charset = match.captures.first if match
      end
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

    @body = @body.to_utf8(charset) if charset

    return @body = @body.strip
  end

  def body
    @body ||= extract_body
  end

  def canonicalized_from_email
    email = header['From'].split(/[^\w@\+\.\-_]/).select { |s| s =~ /@/ }.first
    parts = email.split('@')
    parts.first.gsub!(/\./, '') if email[-10..-1] == '@gmail.com'
    parts.first.gsub!(/\+.*/, '')
    parts.join('@')
  end

  # Guess if this message actually starts a new thread instead of replying to parent
  # maybe this huge thing should be its own class
  def likely_thread_creation_from? parent
    return false if n_subject == parent.n_subject # didn't change subject, almost certainly a reply

    score = -1 # generally, messages are not lazy replies
    score += 1 if references.empty? or !references.include?(parent.message_id)
    quoted_line_count = body.scan(/^> .+/).count
    score -= quoted_line_count
    score += 1 if quoted_line_count == 0

    def top_long_words str, amount=10
      counts = Hash.new { 0 }
      str.downcase.split(/\s+/).each { |word| counts[word] += 1 if word.length > 5 }
      counts.sort_by { |word, count| count }.reverse[0..amount].map { |i| i[0] }
    end

    # lots of points for matching words in subject and to/from
    similar = 0
    similar += (top_long_words(subject.to_s) & top_long_words(parent.subject.to_s)).count * 2
    similar += (top_long_words(header['To']) & top_long_words(header['From'])).count * 2
    similar += (top_long_words(body) & top_long_words(parent.body, 20)).count

    score -= 1 if similar > 6
    score -= 1 if similar > 10

    return score > 0
  end

  def list
    header_addresses = %w{
      X-Mailing-List List-Id X-ML-Name
      List-Post List-Owner List-Help X-MLServer X-ML-Info
      Resent-To Resent-Cc Resent-Reply-To Resent-Bcc
      Mail-Followup-To Mail-Reply-To
      To Cc Reply-To Bcc From
    }.map { |h| header[h] }.select { |s| s != '' }

    possible_addresses = header_addresses.map do |raw|
      raw.chomp.split(/[^\w@\.\-_]/).select { |s| s =~ /@/ }
    end.flatten!

    @list = ListAddressStorage.find_list_by_addresses(possible_addresses)
  end

  def == other
    other.body == body and
    (other.message_id == message_id or (!other.message_id.valid? and !message_id.valid?)) and
    other.subject == subject and
    other.from == from and
    other.references == references and
    other.date.to_i == date.to_i and
    other.no_archive == no_archive
  end
end
