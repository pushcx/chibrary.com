not_found do
  @e = env['sinatra.error']
  haml :'error/not_found.html'
end
