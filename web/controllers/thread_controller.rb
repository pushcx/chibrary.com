get  '/:slug/:year/:month/:call_number' do
  load_list
  load_month
  load_thread

  @title = "#{subject(@thread.subject)} - #{@list['name'] or @slug}"
  @previous_link, @next_link = thread_previous_next(@slug, @year, @month, @call_number)

  haml :'thread/show.html'
end
