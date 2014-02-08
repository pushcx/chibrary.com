#class LogMessageController < ApplicationController
  #before_filter :verify_log_passwd

  def create
    @log_message = LogMessage.new params[:log_message]
    # There's nothing user-editable in params, so it doesn't make sense to render an error form
    @log_message.save
    render :text => "1"
  end

  private

  def verify_log_passwd
    redirect_to root_path and return false unless params[:passwd] != LOG_PASSWD
  end
#end
