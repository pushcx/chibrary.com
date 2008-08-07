# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  session :off
  helper :all # include all helpers, all the time
  helper_method :f, :subject
  before_filter :title

  protect_from_forgery :secret => 'b6f6fc35252f52ac9a9bf52f129b0ac3'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  private
  def title
    @title = "ListLibrary.net - Free Mailing List Archives"
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

  def load_list_snippets
    @snippets = []
    begin
      $archive["snippet/list/#{@slug}"].each_with_index { |key, i| @snippets << $archive["snippet/list/#{@slug}/#{key}"] ; break if i >= 30 }
    rescue NotFound ; end
  end

  def render_optional_error_file status_code
    return super unless status_code == :not_found
    @slug ||= (request.request_uri or '').split('/')[1]
    load_list_snippets if @slug
    render :template => "error/missing.html.haml", :status => 404
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
    if @list and marker = @list['marker']
      subj = subj[marker.length..-1].strip if subj.downcase[0...marker.length] == marker.downcase
    else
      subj = subj.gsub(/\[.*?\]/, '')
    end
    subj
  end
end
