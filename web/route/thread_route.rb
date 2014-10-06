def load_thread call_number
  root_call_number = ThreadRepo.root_for(call_number)
  if root_call_number != call_number
    redirect_to "/#{@slug}/thread/#{root_call_number}#m-#{call_number}"
  end
  @thread = ThreadRepo.find_with_messages(call_number)
rescue NotFound
  raise Sinatra::NotFound, "Thread not found (unknown call number)"
rescue InvalidCallNumber
  raise Sinatra::NotFound, "Thread not found (invalid call number)"
end

get  '/:slug/thread/:call_number' do
  load_list
  load_thread CallNumber.new(params[:call_number])

  @title = "#{subject(@thread.subject)} - #{@list.title_name}"
  @previous_link, @next_link = thread_previous_next(@thread)

  haml :'thread/show.html'
end
