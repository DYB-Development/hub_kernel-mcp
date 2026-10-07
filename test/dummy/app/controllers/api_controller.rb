class ApiController < ActionController::API
  before_action { head :unauthorized unless current_person }

  private

  def current_person = request.headers["X-Person"]

  def current_account = request.headers["X-Account"]
end
