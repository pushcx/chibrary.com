#ActionController::Routing::Routes.draw do |map|
#  map.resources :log_messages
#
#  map.connect '',       :controller => 'generic', :action => 'homepage'
#
#  map.resources :flags, :only => [ :create ]
#  map.resources :log, :only => [ :create ]
#
#end

before do
  @title = "ListLibrary.net - Free Mailing List Archives"
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
  raise ActionController::RoutingError, "Unknown list" unless $archive.has_key? "list/#{@slug}"
  @list = List.new(@slug)
rescue InvalidSlug
  raise ActionController::RoutingError, "Invalid list slug"
end

def load_month
  @year, @month = params[:year], params[:month]
  raise ActionController::RoutingError, "Invalid year" unless @year =~ /^\d{4}$/
  raise ActionController::RoutingError, "Invalid month" unless @month =~ /^\d{2}$/
  raise ActionController::RoutingError, "Ridiculous month" unless (1..12).include? @month.to_i
end

def load_thread
  @call_number = params[:call_number]
  raise ActionController::RoutingError, "Invalid call_number" unless @call_number =~ /^[A-Za-z0-9\-_]{8}$/
  begin
    # redirects are pending on Threader caching them into a new model
    #r = ThreadList.new(@slug, @year, @month).redirect? @call_number
    #redirect_to "#{r}#m-#{@call_number}" and return if r
    @thread = MessageContainerStorage.find(@list.slug, year, month, call_number)
  rescue NotFound
    raise ActionController::RoutingError, "Thread not found"
  end
end

def thread_previous_next(slug, year, month, call_number)
  def thread_link thread, type
    rel = type ? " rel='#{type} prefetch'" : ''
    "<a href='#{thread.href}' #{rel}>#{f(subject(thread.subject))}</a>"
  end

  if previous_thread = TimeSortStorage.previous_link(slug, year, month, call_number)
    previous_link = "&lt; #{thread_link(previous_thread, :prev)}"
    previous_link += "<br />#{previous_thread.year}-#{previous_thread.month}" if previous_thread.year != year or previous_thread.month != month
  else
    previous_link = "<a class='none' href='/#{slug}' rel='contents'>list</a>"
  end

  if next_thread = TimeSortStorage.previous_link(slug, year, month, call_number)
    next_link = "#{thread_link(next_thread, :next)} &gt;"
    next_link += "<br />#{next_thread.year}-#{next_thread.month}" if next_thread.year != year or next_thread.month != month
  else
    next_link = "<a class='none' href='/#{slug}' rel='contents'>list</a>"
  end

  [previous_link, next_link]
end

def month_previous_next(slug, year, month)
  list = List.new(slug)

  p = Time.utc(year, month).plus_month(-1)
  p_month = "%02d" % p.month
  if list.thread_list(p.year, p_month).message_count > 0
    p_link = "<a href='/#{slug}/#{p.year}/#{p_month}' rel='prev'>#{p.year}-#{p_month}</a>"
  else
    p_link = "<a class='none' href='/#{slug}' rel='contents'>list</a>"
  end

  n = Time.utc(year, month).plus_month(1)
  n_month = "%02d" % n.month
  if list.thread_list(n.year, n_month).message_count > 0
    n_link = "<a href='/#{slug}/#{n.year}/#{n_month}' rel='next'>#{n.year}-#{n_month}</a>"
  else
    n_link = "<a class='none' href='/#{slug}' rel='contents'>list</a>"
  end

  return [p_link, n_link]
end

def load_list_snippets
  @snippets = []
  begin
    $archive["snippet/list/#{@slug}"].each_with_index { |key, i| @snippets << $archive["snippet/list/#{@slug}/#{key}"] ; break if i >= 30 }
  rescue NotFound ; end
end


helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end
