
class CallNumber
  attr_reader :slug

  def initialize slug
    @slug = (slug || '').to_s
  end

  def valid?
    slug =~ /\A[a-zA-Z0-9]{10}\Z/
  end

  def == other
    to_s == other.to_s
  end

  def to_s
    slug
  end

  def self.generate

  end
end
