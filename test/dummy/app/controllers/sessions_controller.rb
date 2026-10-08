class SessionsController < ApplicationController
  def create
    session[:person] = params[:person]
    redirect_to params[:return_to]
  end
end
