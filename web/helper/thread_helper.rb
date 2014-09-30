def message_body m
  str = m.body.strip
  #str = remove_footer(str, m.list)
  str = f(str)
  str = compress_quotes(str)
  str = html_caps(str)
  str
end

def html_caps str
  str.gsub(/\b([A-Z]{3,})\b/, '<span class="caps">\1</span>')
end

def remove_footer str, list
  # remove footer
  if footer = list.footer and         # the list has a footer
      i = str.rindex(footer) and      # and it's here
      i + footer.length == str.length # and it's at the end
    str = str[0..(i - 1)]
  end
  str.strip!
end

def compress_quotes str
  str.sub!(/-----BEGIN [GP]+ SIGNED MESSAGE-----\n.*?\n\n(.*?)\n*-----BEGIN [GP]+ SIGNATURE-----.*/m, '\1')
  str.gsub!(/(^-{4,}[^\-\n]{8,}-{4,}\n.*|(^[^\n]{10,}:\n\n?|)(^&gt;[^\n]*=(20|)\n[^\n]*\n|^&gt;[^\n]*\n(\s*?\n&gt;[^\n]*\n)*)+\n*)/m) do
    quote = $1.split(/\n/)
    quote.shift while quote.first =~ /^&gt;\s*$/
    quote.pop   while quote.last  =~ /^&gt;\s*$/
    lines = quote.length
    quote = quote.join("\n")
    if lines <= 3
      '</pre><blockquote class="short"><pre>' + quote + "</pre></blockquote><pre>\n"
    else
      '</pre><blockquote><pre>' + quote + "</pre></blockquote><pre>\n"
    end
  end
  str.strip
end

# This could be rewritten to be a query instead of a command, and probably
# should be some kind of presenter around Container.
def container_partial c
  return partial('thread/_message_missing.html') if c.empty?
  return partial('thread/_message_no_archive.html') if c.message.no_archive

  partial('thread/_message.html', locals: {
    message:  c.message,
    parent:   c.root? ? nil : c.parent.message,
    children: c.children.sort.collect { |c| c.message unless c.empty? }.compact,
  })
end
