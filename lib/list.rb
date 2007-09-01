require 'aws'

class List < CachedHash
  def initialize list
    super "list/#{list}"
  end
end
