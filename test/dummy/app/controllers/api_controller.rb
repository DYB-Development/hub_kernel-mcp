class ApiController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action { head :unauthorized unless current_person }

  private

  def current_person = request.headers["X-Person"] || connected_person&.id

  def connected_person = authenticate_with_http_token { |token| HubKernel::Mcp::Connection.person_for(token) }

  def current_account = request.headers["X-Account"] || ("acme" if connected_person)
end
