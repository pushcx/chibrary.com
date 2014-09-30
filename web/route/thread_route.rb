def load_thread call_number
  thread = ThreadRepo.find_with_messages(@call_number)
rescue NotFound
  load_redirect call_number
rescue InvalidCallNumber
  raise Sinatra::NotFound, "Thread not found (invalid call number)"
end

def load_redirect call_number
  root_call_number = ThreadRepo.root_for(call_number)
  redirect_to "/thread/#{root_call_number}#m-#{call_number}"
rescue NotFound
  raise Sinatra::NotFound, "Thread not found (unknown call number)"
end

get  '/:slug/:year/:month/:call_number' do
  load_list
  load_month
  load_thread CallNumber.new(params[:call_number])

  @title = "#{subject(@thread.subject)} - #{@list.title_name}"
  @previous_link, @next_link = thread_previous_next(@thread)

  haml :'thread/show.html'
end
