# format (hide mail addresses, link URLs) and html-escape a string
def f str
  str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([\w]+)/, '\1@\2...\3') # hide mail addresses
  str = CGI::escapeHTML(str)
  str.gsub(/(\w+:\/\/[^\s]+)/m, '<a rel="nofollow" href="\1' + '">\1</a>') # link urls
end

def from from
  f from
end
