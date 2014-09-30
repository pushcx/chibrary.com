def load_message call_number
  @message = MessageRepo.find(call_number)
  #@thread_call_number = ThreadRepo.root_for(call_number)
rescue NotFound
  raise Sinatra::NotFound, "Thread not found (unknown call number)"
rescue InvalidCallNumber
  raise Sinatra::NotFound, "Message not found (invalid call number)"
end

get  '/:slug/message/:call_number' do
  load_list
  load_message CallNumber.new(params[:call_number])

  @title = "#{subject(@message.subject)} - #{@list.title_name}"

  haml :'message/show.html'
end
