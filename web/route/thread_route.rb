require_relative '../../model/sym'

def load_thread(call_number)
  begin
    r = RedirectMapStorage.find(Sym.new(@slug, @year, @month)).redirect? @call_number
    redirect_to "#{r}#m-#{@call_number}" and return if r
    @thread = MessageContainerStorage.find(call_number)
  rescue NotFound
    raise ArgumentError, "Thread not found"
  end
end

get  '/:slug/:year/:month/:call_number' do
  call_number = CallNumber.new(params[:call_number])
  raise ArgumentError, "Invalid Call Number" unless call_number.valid?

  load_list
  load_month
  load_thread(call_number)

  @title = "#{subject(@thread.subject)} - #{@list.title_name}"
  @previous_link, @next_link = thread_previous_next(Sym.new(@slug, @year, @month), @call_number)

  haml :'thread/show.html'
end
