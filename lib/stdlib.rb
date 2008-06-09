module Enumerable
  def sum ; inject(0) { |x, y| x + y }; end
end

class Symbol
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end
