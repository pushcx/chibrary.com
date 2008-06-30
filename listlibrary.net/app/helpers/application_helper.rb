# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
end

class String
  def to_base_36 
    chars = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a + ['_', '-']
    chars = chars.collect { |c| c.to_s }

    n = 0
    self.split('').reverse.each_with_index do |char, i|
      val = chars.index(char) * (64 ** i)
      n += val
    end
    n.to_base_36
  end
end
