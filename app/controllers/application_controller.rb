# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :title

  protect_from_forgery

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
    raise ActionController::RoutingError, "Ridiculous month" unless (1..12).include? @month.to_i
  end

  def render_optional_error_file status_code
    return super unless status_code == :not_found
    @slug ||= (request.request_uri or '').split('/')[1]
    load_list_snippets if @slug
    render :template => "error/missing.html.haml", :status => 404
  end
end
