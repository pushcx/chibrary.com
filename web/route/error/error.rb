unless Sinatra::Application.development?
  error do
    @e = env['sinatra.error']
    haml :'error/error.html'
  end
end
