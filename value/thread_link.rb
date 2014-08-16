require 'adamantium'

module Chibrary

ThreadLink = Struct.new(:sym, :call_number, :subject) do
  include Adamantium

  def href
    "/#{sym.slug}/#{call_number}"
  end
  alias :to_s :href

  def inspect
    "<Chibrary::ThreadLink:0x%x #{to_s}'>" % (object_id << 1)
  end
end

end # Chibrary
