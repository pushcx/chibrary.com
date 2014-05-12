require_relative '../../value/sym'

def load_thread(call_number)
  begin
    r = RedirectMapRepo.find(Sym.new(@slug, @year, @month)).redirect? @call_number
    redirect_to "#{r}#m-#{@call_number}" and return if r
    @thread = MessageContainerRepo.find(call_number)
  rescue NotFound, InvalidCallNumber
    raise Sinatra::NotFound, "Thread not found"
  end
end

get  '/:slug/:year/:month/:call_number' do
  call_number = CallNumber.new(params[:call_number])

  load_list
  load_month
  load_thread(call_number)

  @title = "#{subject(@thread.subject)} - #{@list.title_name}"
  @previous_link, @next_link = thread_previous_next(Sym.new(@slug, @year, @month), @call_number)

  haml :'thread/show.html'
end
