class ListController < ApplicationController
  before_filter :load_list

  def show
    @year_counts = @list.year_counts
  end
end
