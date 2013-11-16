# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController
  #before_filter :title

  private

  def render_optional_error_file status_code
    return super unless status_code == :not_found
    @slug ||= (request.request_uri or '').split('/')[1]
    load_list_snippets if @slug
    render :template => "error/missing.html.haml", :status => 404
  end
end
