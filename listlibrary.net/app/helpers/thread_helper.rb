module ThreadHelper
  def message_body m
    str = m.body
    str = remove_footer(str, m.slug)
    str = f(str)
    str = compress_quotes(str)
    #str.gsub!(/([A-Z]{3,})/, '<span class="caps">\1</span>')
    str
  end

  def remove_footer str, slug
    list = List.new(slug)
    
    # remove footer
    if footer = list['footer'] and     # the list has a footer
       i = str.rindex(footer) and      # and it's here
       i + footer.length == str.length # and it's at the end
      str = str[0..(i - 1)]
    end
    str.strip
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

  def container_partial c
    return render(:partial => 'message_missing') if c.empty?
    return render(:partial => 'message_no_archive') if c.message.no_archive

    begin
      render(:partial => 'message', :locals => {
        :message => c.message,
        :parent => c.root? ? nil : c.parent.message,
        :children => c.children.sort.collect { |c| c.message unless c.empty? }.compact,
      })
    rescue NotFound
      render(:partial => 'message_missing')
    end
  end
end
