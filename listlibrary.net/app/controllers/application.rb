# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  session :off
  helper :all # include all helpers, all the time
  helper_method :f, :subject
  after_filter :title

  protect_from_forgery :secret => 'b6f6fc35252f52ac9a9bf52f129b0ac3'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  private
  def title
    if @title
      @title += " - ListLibrary.net"
    else
      @title = "ListLibrary.net - Free Mailing List Archives"
    end
  end

  def load_list
    @slug = params[:slug]
    raise ActionController::RoutingError, "Invalid list slug" unless @slug =~ /^[a-z0-9\-]+$/ and @slug.length <= 20
    raise ActionController::RoutingError, "Unknown list" unless $archive.has_key? "list/#{@slug}"
    @list = List.new(@slug)
  end

  def load_month
    @year, @month = params[:year], params[:month]
    raise ActionController::RoutingError, "Invalid year" unless @year =~ /^\d{4}$/
    raise ActionController::RoutingError, "Invalid month" unless @month =~ /^\d{2}$/
  end


  # format (hide mail addresses, link URLs) and html-escape a string
  def f str
    str.gsub!(/([\w\-\.]*?)@(..)[\w\-\.]*\.([a-z]+)/, '\1@\2...\3') # hide mail addresses
    str = CGI::escapeHTML(str)
    str.gsub(/(\w+:\/\/[^\s]+)/m, '<a rel="nofollow" href="\1' + '">\1</a>') # link urls
  end

  def subject o
    subj = (o.is_a? String) ? o : o.n_subject
    subj = subj.empty? ? '<i>no subject</i>' : subj
    if marker = @list['marker']
      subj = subj[marker.length..-1].strip if subj.downcase[0...marker.length] == marker.downcase
    end
    subj
  end
end
