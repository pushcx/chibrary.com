class ListController < ApplicationController
  before_filter :load_list
  caches_page :show

  def show
    @title = "#{@list['name'] or @slug} archive"
    @year_counts = @list.year_counts
  end
end
