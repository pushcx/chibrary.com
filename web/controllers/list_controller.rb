get  '/:slug/:year/?' do
  redirect "/#{params[:slug]}"
end

class ListController < ApplicationController
  #before_filter :load_list, :load_list_snippets, :except => :year_redirect

  def show
    @title = "#{@list['name'] or @slug} archive"
    @year_counts = ThreadList.year_counts @slug
  end

  private

  def load_list_snippets
    @snippets = []
    begin
      $archive["snippet/list/#{@slug}"].each_with_index { |key, i| @snippets << $archive["snippet/list/#{@slug}/#{key}"] ; break if i >= 30 }
    rescue NotFound ; end
  end
end
