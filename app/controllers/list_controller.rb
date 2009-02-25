class ListController < ApplicationController
  before_filter :load_list, :load_list_snippets, :except => :year_redirect
  caches_page :show

  def show
    @title = "#{@list['name'] or @slug} archive"
    @year_counts = ThreadList.year_counts @slug
  end

  def year_redirect
    redirect_to :action => 'show'
  end
end
