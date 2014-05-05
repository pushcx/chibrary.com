require_relative '../lib/core_ext/ice_nine_'

ThreadLink = Struct.new(:sym, :call_number, :subject) do
  prepend IceNine::DeepFreeze

  def href
    "/#{sym.to_key}/#{call_number}"
  end
end
