require 'adamantium'
require 'base62'
require 'base64'
require 'digest/sha2'
require 'rmail'
require 'time'

require_relative 'headers'
require_relative 'subject'
require_relative 'message_id'

module Chibrary

class Email
  include Adamantium

  attr_reader :raw, :header

  def initialize raw
    @raw        = raw
    @header     = Headers.new raw
  end

  def message_id
    MessageId.new header['Message-Id']
  end
  memoize :message_id

  def subject
    h = header['Subject']
    Subject.new h != '' ? h : '[missing subject]'
  end
  memoize :subject

  def n_subject
    subject.normalized
  end

  def from
    header['From'].sub(/"(.*?)"/, '\1').decoded
  end
  memoize :from

  def references
    "#{header['References']} #{header['In-Reply-To']}".
      split(/\s+/).
      map { |s| MessageId.new(s) }.
      select { |m| m.valid? }.
      uniq
  end
  memoize :references

  def date
    # Received headers are prepended, so we can take the first value there
    # and fall back to Date
    (header.all('Received') << header['Date']).
      map { |s| s.gsub(/\n */m, ' ').
      split(';') }.flatten.each do |raw|
        begin
          return Time.rfc2822(raw).utc
        rescue ArgumentError
          begin
            # if it didn't manage an rfc date, hope for iso date. This is nice
            # when Emails have to be reconstructed from an archive.
            return Time.parse(raw + " UTC").utc
          rescue ArgumentError
            # If it's completely fucked, well, now is as good at time as any.
            return Time.now.utc
          end
        end
    end
    return Time.now.utc
  end
  memoize :date

  def no_archive?
    (
      header['X-No-Archive'] =~ /yes/i or
      header['X-Archive'] != '' or
      header['Archive'] =~ /no/i
    )
  end
  memoize :no_archive?

  def body
    return '' if raw.nil? # body is not serialized

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
        extracted_body = part.body
        break
      end
    end

    if extracted_body.nil? # didn't find a text/plain body
      extracted_body = "This MIME-encoded message did not include a plain text body or could not be decoded."
    end

    case encoding
    when /quoted-printable/i
      extracted_body = extracted_body.unpack('M').first
    when /base64/i
      extracted_body = extracted_body.unpack('m').first
    end # else it's fine

    extracted_body = extracted_body.to_utf8(charset) if charset

    return extracted_body.strip
  end
  memoize :body

  def canonicalized_from_email
    from = header['From']

    # if there is no @, try for a censored email
    if !from.include?('@') and from.include?(' at ')
      from = from.gsub(' at ', '@')
    end
    if !from.include?('@')
      return 'no.email.address@chibrary.com'
    end

    # try for a properly-formatted "User <a@example.com>" but take anything
    if match = from.match(/<(.*@.*)>/)
      email = match.captures.first
    else
      email = from.split(/[^\w@\+\.\-_]/).select { |s| s.include? '@' }.first
    end
    parts = email.split('@')
    unless parts.first.nil?
      parts.first.gsub!(/\./, '') if email[-10..-1] == '@gmail.com'
      parts.first.gsub!(/\+.*/, '')
    end
    parts.join('@')
  end
  memoize :canonicalized_from_email

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

  def possible_list_addresses
    header_addresses = %w{
      X-Mailing-List List-Id X-ML-Name
      List-Post List-Owner List-Help X-MLServer X-ML-Info
      Resent-To Resent-Cc Resent-Reply-To Resent-Bcc
      Mail-Followup-To Mail-Reply-To
      To Cc Reply-To Bcc From
    }.map { |h| header[h] }.select { |s| s != '' }

    possible_addresses = header_addresses.map do |raw|
      raw.chomp.split(/[^\w@\.\-_]/).select { |s| s =~ /@/ }
    end.flatten
  end
  memoize :possible_list_addresses

  def mid_hash
    raise 'No CHIBRARY_SALT in environment' unless ENV['CHIBRARY_SALT']

    return nil unless message_id.valid?

    value = [
      ENV['CHIBRARY_SALT'],
      message_id.to_s,
    ].join('')
    Digest::SHA2.hexdigest(value).to_i(16).base62_encode
  end
  memoize :mid_hash

  def vitals_hash
    raise 'No CHIBRARY_SALT in environment' unless ENV['CHIBRARY_SALT']

    value = [
      ENV['CHIBRARY_SALT'],
      # an archive could break this by...
      date.strftime("%Y-%m-%d %H:%M"), # ...dropping TZ info or time
      from, # ...censoring email addresses
      n_subject, #...or truncating the subject
    ].join('')

    Digest::SHA2.hexdigest(value).to_i(16).base62_encode
  end
  memoize :vitals_hash

  def inspect
    "<Chibrary::Email:0x%x id:#{message_id}>" % (object_id << 1)
  end

  def == other
    other.raw == raw
  end

  # TODO should find top-quoted quotes, quote is waiting to be a class
  def quotes
    body.scan(/^> /).collect { |q| q.sub(/^(> *)*/, '') }
  end

  def direct_quotes
    body.scan(/^> *[^>].+/).collect { |q| q.sub(/^> */, '') }
  end

  def new_text
    body.split("\n").select { |l| l !~ /^>/ }.join(' ') # some quoters wrap funny
  end
  memoize :new_text

  def lines_matching quoted
    quoted.collect { |q| (new_text.include? q) ? 1 : 0 }.inject(0, &:+)
  end
end

end # Chibrary
