class String
  def decoded
    self.gsub(/=\?[^\?]+\?[^\?]+\?[^\?]+\?=/) do |encoded|
      charset, encoding, text = *encoded.match(/=\?([^\?]+)\?([^\?]+)\?([^\?]+)\?=/).captures
      if encoding == 'B'
        text = text.unpack('m').first
      elsif encoding == 'Q'
        text = text.unpack('M').first
      end
      text.to_utf8
    end
  end

  def to_utf8
    self.encode("UTF-8", :invalid => :replace, :undef => :replace).force_encoding('UTF-8')
  end
end
