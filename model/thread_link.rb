ThreadLink = Struct.new(:sym, :call_number, :subject) do
  def href
    "/#{sym.to_key}/#{call_number}"
  end
end
