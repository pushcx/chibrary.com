require 'rubygems'
require 'cgi'
require 'haml'
require 'tidy'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'
require 'list'
require 'time_'

class String
  def to_base_36 
    chars = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a + ['_', '-']
    chars = chars.collect { |c| c.to_s }

    n = 0
    self.split('').reverse.each_with_index do |char, i|
      val = chars.index(char) * (64 ** i)
      puts "char #{char}, i #{i}, position #{chars.index(char)}, val #{val}, n #{n}"
      n += val
    end
    puts "#{self} -> #{n.to_base_36}"
    n.to_base_36
  end
end

class View
  def self.render options={}
    locals = (options[:locals] or {})
    if locals[:collection]
      return locals[:collection].collect do |item|
        locals[options[:partial]] = item
        View.render options.merge({ :collection => nil, :locals => locals })
      end.join("\n")
    end

    locals[:title] = (locals[:title].to_s + " - ListLibrary").strip.sub(/^- /, '')

    filename = (options[:page] or options[:partial])
    html = if options[:page]
      Haml::Engine.new(File.read("view/layout.haml"), :locals => locals, :filename => "layout").render(View) do
        Haml::Engine.new(File.read("view/#{filename}.haml"), :locals => locals, :filename => filename).render(View)
      end
    elsif options[:partial]
      Haml::Engine.new(File.read("view/#{filename}.haml"), :locals => locals, :filename => filename).render(View)
    end

    unless options[:partial]
      Tidy.path = '/usr/lib/libtidy.so'
      tidy_options = {
        'doctype' => 'omit',
        'tidy-mark' => 'false',
        'show-body-only' => 'true',
        'new-blocklevel-tags' => 'pre',
      }
      Tidy.open(tidy_options) do |tidy|
        tidy.clean(html)
        $stderr.puts html unless tidy.errors.empty?
        raise "Tidy found errors rendering #{options.inspect}: \n" + tidy.errors.join("\n") unless tidy.errors.empty?
      end
    end
    html
  end

  # helpers

  def self.message_body m
    str = m.body
    str = remove_footer(str, m.slug)
    str = h(str)
    str = compress_quotes(str)
    str.gsub!(/([A-Z]{3,})/, '<span class="caps">\1</span>')
    str
  end

  def self.remove_footer str, slug
    list = List.new(slug)
    
    # remove footer
    if footer = list['footer'] and     # the list has a footer
       i = str.rindex(footer) and      # and it's here
       i + footer.length == str.length # and it's at the end
      str = str[0..(i - 1)]
    end
    str.strip
  end

  def self.compress_quotes str
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

  def self.h str
    str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([a-z]+)/, '\1@\2...\3') # hide mail addresses
    str = CGI::escapeHTML(str)
    str.gsub(/(\w+:\/\/[^\s]+)/m, '<a rel="nofollow" href="\1' + '">\1</a>') # link urls
  end

  def self.container_partial c
    if c.empty?
      View::render(:partial => 'message_missing')
    elsif c.message.no_archive
      View::render(:partial => 'message_no_archive')
    else
      # Load the full message from s3 to get body and etc.
      View::render(:partial => 'message', :locals => {
        :message => Message.new(c.message.key.to_s.gsub('+',' ')),
        :parent => c.root? ? nil : c.parent.message,
        :children => c.children.sort.collect { |c| c.message unless c.empty? }.compact,
      })
    end
  end

  def self.subject o
    subj = o.n_subject
    (subj.empty? ? '<i>no subject</i>' : subj)
  end
end
