%h1 Not Found

%p Nothing found at that URL.

  a
%pre Sinatra::Application.development?
- if Sinatra::Application.development?
  %pre= "#{@e.class}: #{@e.message}\n\n#{@e.backtrace.reject { |s| s =~ /\/gems\// }.join("\n")}"
