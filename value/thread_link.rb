require 'adamantium'

ThreadLink = Struct.new(:sym, :call_number, :subject) do
  include Adamantium

  def href
    "/#{sym.to_key}/#{call_number}"
  end
end
