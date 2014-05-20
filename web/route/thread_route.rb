require_relative '../../value/sym'

def load_thread
  @call_number = CallNumber.new(params[:call_number])
  r = RedirectMapRepo.find(@sym).redirect? @call_number
  redirect_to "#{r}#m-#{@call_number}" and return if r
  @thread = MessageContainerRepo.find(@call_number)
rescue NotFound, InvalidCallNumber
  raise Sinatra::NotFound, "Thread not found"
end

get  '/:slug/:year/:month/:call_number' do
  load_list
  load_month
  load_thread

  @title = "#{subject(@thread.subject)} - #{@list.title_name}"
  @previous_link, @next_link = thread_previous_next(@sym, @call_number)

  haml :'thread/show.html'
end
