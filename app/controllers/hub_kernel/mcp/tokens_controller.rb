module HubKernel
  module Mcp
    class TokensController < ActionController::API
      def create
        code = AuthorizationCode.find_by(code_digest: AuthorizationCode.digest(params[:code].to_s))
        return render(status: :bad_request, json: { error: "invalid_grant" }) unless exchangeable?(code)

        tokens = Connection.issue(person: code.person, client: code.client)
        render json: { access_token: tokens.access_token, token_type: "Bearer", expires_in: Connection::LIFETIME.to_i, refresh_token: tokens.refresh_token }
      end

      private

      def exchangeable?(code) = code.present? && code.expires_at.future? && code.client.uid == params[:client_id] && code.redirect_uri == params[:redirect_uri] && code.verifies?(params[:code_verifier]) && used_up?(code)

      def used_up?(code) = AuthorizationCode.where(id: code.id).delete_all == 1
    end
  end
end
