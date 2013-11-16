class FlagController < ApplicationController
  def create
    @flag = Flag.new params[:flag]
    # There's nothing user-editable in params, so it doesn't make sense to render an error form
    @flag.save
    render :text => "Flagged, thanks."
  end
end
