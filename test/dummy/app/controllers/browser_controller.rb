class BrowserController < ApplicationController
  private

  def sign_in_person
    redirect_to "/sign_in?#{{ return_to: request.fullpath }.to_query}" unless signed_in_person
  end

  def signed_in_person = session[:person] && Person.new(session[:person])
end
