require 'adamantium'

module Chibrary

ThreadLink = Struct.new(:sym, :call_number, :subject) do
  include Adamantium

  def href
    "/#{sym.slug}/#{call_number}"
  end
end

end # Chibrary
