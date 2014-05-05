# format (hide email addresses, link URLs) and html-escape a string
def f str
  str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([\w]+)/, '\1@\2...\3') # hide email addresses
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

def load_list
  @slug = params[:slug]
  @list = ListStorage.find(@slug)
rescue NotFound
  raise ActionController::RoutingError, "Unknown list"
rescue InvalidSlug
  raise ActionController::RoutingError, "Invalid list slug"
end

def load_month
  @year, @month = params[:year], params[:month]
  raise ActionController::RoutingError, "Invalid year" unless @year =~ /^\d{4}$/
  raise ActionController::RoutingError, "Invalid month" unless @month =~ /^\d{2}$/
  raise ActionController::RoutingError, "Ridiculous month" unless (1..12).include? @month.to_i
end

def thread_previous_next(sym, call_number)
  def thread_link thread, type
    rel = type ? " rel='#{type} prefetch'" : ''
    "<a href='#{thread.href}' #{rel}>#{f(subject(thread.subject))}</a>"
  end

  if previous_thread = TimeSortStorage.previous_link(sym, call_number)
    previous_link = "&lt; #{thread_link(previous_thread, :prev)}"
    previous_link += "<br />#{previous_thread.year}-#{previous_thread.month}" unless sym.same_time_as? previous_thread
  else
    previous_link = "<a class='none' href='/#{sym.slug}' rel='contents'>list</a>"
  end

  if next_thread = TimeSortStorage.previous_link(sym, call_number)
    next_link = "#{thread_link(next_thread, :next)} &gt;"
    next_link += "<br />#{next_thread.year}-#{next_thread.month}" if sym.same_time_as? next_thread
  else
    next_link = "<a class='none' href='/#{sym.slug}' rel='contents'>list</a>"
  end

  [previous_link, next_link]
end

def month_previous_next(sym)
  list = List.new(sym.slug)

  p = Time.utc(sym.year, sym.month).plus_month(-1)
  p_month = "%02d" % p.month
  if list.thread_list(p.year, p_month).message_count > 0
    p_link = "<a href='/#{slug}/#{p.year}/#{p_month}' rel='prev'>#{p.year}-#{p_month}</a>"
  else
    p_link = "<a class='none' href='/#{slug}' rel='contents'>list</a>"
  end

  n = Time.utc(sym.year, sym.month).plus_month(1)
  n_month = "%02d" % n.month
  if list.thread_list(n.year, n_month).message_count > 0
    n_link = "<a href='/#{slug}/#{n.year}/#{n_month}' rel='next'>#{n.year}-#{n_month}</a>"
  else
    n_link = "<a class='none' href='/#{slug}' rel='contents'>list</a>"
  end

  return [p_link, n_link]
end
