module HubKernel
  module Mcp
    class TokensController < ActionController::API
      def create
        code = AuthorizationCode.find_by(code_digest: AuthorizationCode.digest(params[:code].to_s))
        return render(status: :bad_request, json: { error: "invalid_grant" }) unless code&.verifies?(params[:code_verifier])

        token = Connection.issue(person: code.person, client: code.client)
        render json: { access_token: token, token_type: "Bearer", expires_in: Connection::LIFETIME.to_i }
      end
    end
  end
end
