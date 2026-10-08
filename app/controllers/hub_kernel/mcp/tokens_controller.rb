module HubKernel
  module Mcp
    class TokensController < ActionController::API
      def create
        code = AuthorizationCode.find_by(code_digest: AuthorizationCode.digest(params[:code].to_s))
        return render(status: :bad_request, json: { error: "invalid_grant" }) unless exchangeable?(code)

        token = Connection.issue(person: code.person, client: code.client)
        render json: { access_token: token, token_type: "Bearer", expires_in: Connection::LIFETIME.to_i }
      end

      private

      def exchangeable?(code) = code.present? && code.redirect_uri == params[:redirect_uri] && code.verifies?(params[:code_verifier])
    end
  end
end
