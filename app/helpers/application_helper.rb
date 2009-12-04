# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # format (hide mail addresses, link URLs) and html-escape a string
  def f str
    str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([\w]+)/, '\1@\2...\3') # hide mail addresses
    str = CGI::escapeHTML(str)
    str.gsub(/(\w+:\/\/[^\s]+)/m, '<a rel="nofollow" href="\1' + '">\1</a>') # link urls
  end

  def from from
    f from
  end

  def subject o
    subj = (o.is_a? String) ? o : o.n_subject
    subj = subj.blank? ? '<i>no subject</i>' : subj
    if @list and marker = @list['marker']
      subj = subj[marker.length..-1].strip if subj.downcase[0...marker.length] == marker.downcase
    else
      subj = subj.gsub(/\[.*?\]/, '')
    end
    return subj
  end
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
