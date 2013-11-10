#ActionController::Routing::Routes.draw do |map|
#  map.resources :log_messages
#
#  map.connect '',       :controller => 'generic', :action => 'homepage'
#
#  map.resources :flags, :only => [ :create ]
#  map.resources :log, :only => [ :create ]
#
#  map.connect ':slug',                           :controller => 'list',   :action => 'show'
#  map.connect ':slug/:year',                     :controller => 'list',   :action => 'year_redirect'
#  map.connect ':slug/:year/:month',              :controller => 'month',  :action => 'show'
#  map.connect ':slug/:year/:month/:call_number', :controller => 'thread', :action => 'show'
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
    r = ThreadList.new(@slug, @year, @month).redirect? @call_number
    redirect_to "#{r}#m-#{@call_number.to_base_36}" and return if r
    @thread = $riak["list/#{@list.slug}/thread/#{@year}/#{@month}/#{@call_number}"]
  rescue NotFound
    raise ActionController::RoutingError, "Thread not found"
  end
end

def thread_previous_next(slug, year, month, call_number)
  def thread_link thread
    "<a href=\"/#{thread[:slug]}/#{thread[:year]}/#{thread[:month]}/#{thread[:call_number]}\">#{f(subject(thread[:subject]))}</a>"
  end
  thread_list = ThreadList.new(slug, year, month)

  if previous_thread = thread_list.previous_thread(call_number)
    previous_link = "&lt; #{thread_link(previous_thread)}"
    previous_link += "<br />#{previous_thread[:year]}-#{previous_thread[:month]}" if previous_thread[:year] != year or previous_thread[:month] != month
  else
    previous_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
  end

  if next_thread = thread_list.next_thread(call_number)
    next_link = "#{thread_link(next_thread)} &gt;"
    next_link += "<br />#{next_thread[:year]}-#{next_thread[:month]}" if next_thread[:year] != year or next_thread[:month] != month
  else
    next_link = "<a class=\"none\" href=\"/#{slug}\">archive</a>"
  end

  [previous_link, next_link]
end
