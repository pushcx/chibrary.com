# format (hide email addresses, link URLs) and html-escape a string
def f str
  str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([\w]+)/, '\1@\2...\3') # hide email addresses
  str = CGI::escapeHTML(str)
  str.gsub(/(\w+:\/\/[^\s]+)/m, '<a rel="nofollow" href="\1' + '">\1</a>') # link urls
end

def from from
  f from.dup
end

def thread_line_from from
  f = from.strip
  if f =~ /\w <?[\w\-\.]+@[\w\-\.]+>?/ # has a name + email
    f.gsub! /(.*) <?[\w\-\.]+@[\w\-\.]+>?/, '\1'
  else
    f.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([\w]+)/, '\1@\2...\3') # hide email domain
  end
end

def subject subj
  subj = subj.to_s
  subj = subj.blank? ? '<i>no subject</i>' : subj
#  if @list and marker = @list['marker']
#    subj = subj[marker.length..-1].strip if subj.downcase[0...marker.length] == marker.downcase
#  else
    subj = subj.gsub(/\[.*?\]/, '')
#  end
  return subj
end

def load_list
  @slug = Slug.new params[:slug]
  @list = ListRepo.find(@slug)
rescue NotFound
  raise Sinatra::NotFound, "Unknown list"
rescue InvalidSlug
  raise Sinatra::NotFound, "Invalid list slug"
end

def load_month
  @sym = Sym.new(@slug, params[:year], params[:month])
rescue ArgumentError
  raise Sinatra::NotFound
end

def thread_previous_next(thread)
  def thread_link thread, type
    rel = type ? " rel='#{type} prefetch'" : ''
    "<a href='/#{thread.slug}/thread/#{thread.call_number}' #{rel}>#{f(subject(thread.n_subject))}</a>"
  end

  if previous_thread = ThreadRepo.new(thread).previous_thread
    previous_link = "&lt; #{thread_link(previous_thread, :prev)}"
    previous_link += "<br />#{previous_thread.sym.when}" unless thread.sym.same_time_as? previous_thread.sym
  else
    previous_link = "<a class='none' href='/#{thread.sym.slug}' rel='contents'>list</a>"
  end

  if next_thread = ThreadRepo.new(thread).next_thread
    next_link = "#{thread_link(next_thread, :next)} &gt;"
    next_link += "<br />#{next_thread.sym.when}" unless thread.sym.same_time_as? next_thread.sym
  else
    next_link = "<a class='none' href='/#{thread.sym.slug}' rel='contents'>list</a>"
  end

  [previous_link, next_link]
end

def month_previous_next(sym)
  list = List.new(sym.slug)
  p = sym.plus_month(-1)
  n = sym.plus_month(1)

  if MonthCountRepo.find(p).message_count > 0
    p_link = "<a href='/#{p.slug}/#{p.year}/#{p.month}' rel='prev'>#{p.when}</a>"
  else
    p_link = "<a class='none' href='/#{p.slug}' rel='contents'>list</a>"
  end

  if MonthCountRepo.find(n).message_count > 0
    n_link = "<a href='/#{n.slug}/#{n.year}/#{n.month}' rel='next'>#{n.when}</a>"
  else
    n_link = "<a class='none' href='/#{n.slug}' rel='contents'>list</a>"
  end

  return [p_link, n_link]
end
