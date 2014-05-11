not_found do
  e = env['sinatra.error']
  if Sinatra::Application.development?
    "#{e.class}: #{e.message}<br><br>#{e.backtrace.reject { |s| s =~ /\/gems\// }.join('<br>')}"
  else
    haml :'error/not_found.html'
  end
end
