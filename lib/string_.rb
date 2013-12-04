class String
  def decoded
    self.gsub(/=\?[^\?]+\?[^\?]+\?[^\?]+\?=/) do |encoded|
      charset, encoding, text = *encoded.match(/=\?([^\?]+)\?([^\?]+)\?([^\?]+)\?=/).captures
      if encoding == 'B'
        # base64
        text = text.unpack('m').first
      elsif encoding == 'Q'
        # quoted-printable, MIME encoding
        text = text.unpack('M').first
      end
      text.to_utf8 charset
    end
  end

  def to_utf8 charset
    self.encode("UTF-8", charset, :invalid => :replace, :undef => :replace).force_encoding('UTF-8')
  end
end
