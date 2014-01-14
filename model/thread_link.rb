ThreadLink = Struct.new(:slug, :year, :month, :call_number, :subject) do
  def href
    "/#{slug}/#{year}/%02d/#{call_number}" % month
  end
end
