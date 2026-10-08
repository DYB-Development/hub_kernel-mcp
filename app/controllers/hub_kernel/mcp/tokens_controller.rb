module HubKernel
  module Mcp
    class TokensController < ActionController::API
      UNUSABLE_CODE = "The code is unknown, used, expired, or does not match this client, redirect address or verifier".freeze

      def create
        tokens = params[:grant_type] == "refresh_token" ? refreshed : exchanged
        return render(status: :bad_request, json: { error: "invalid_grant", error_description: UNUSABLE_CODE }) unless tokens

        render json: { access_token: tokens.access_token, token_type: "Bearer", expires_in: Connection::LIFETIME.to_i, refresh_token: tokens.refresh_token }
      end

      private

      def exchanged
        code = AuthorizationCode.find_by(code_digest: AuthorizationCode.digest(params[:code].to_s))
        Connection.issue(person: code.person, client: code.client) if exchangeable?(code)
      end

      def refreshed = Connection.refresh(params[:refresh_token], client: Client.find_by(uid: params[:client_id]))

      def exchangeable?(code) = code.present? && code.expires_at.future? && code.client.uid == params[:client_id] && code.redirect_uri == params[:redirect_uri] && code.verifies?(params[:code_verifier]) && used_up?(code)

      def used_up?(code) = AuthorizationCode.where(id: code.id).delete_all == 1
    end
  end
end
