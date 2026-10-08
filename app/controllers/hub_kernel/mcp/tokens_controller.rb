module HubKernel
  module Mcp
    class TokensController < ActionController::API
      UNUSABLE_CODE = "The code is unknown, used, expired, or does not match this client, redirect address or verifier".freeze
      UNUSABLE_REFRESH_TOKEN = "The refresh token is unknown, used, unused for ninety days, or belongs to another client".freeze

      rescue_from(ActionDispatch::Http::Parameters::ParseError) { refuse("invalid_request", "The token request body could not be read") }

      def create
        case params[:grant_type]
        when "authorization_code" then answer(exchanged, UNUSABLE_CODE)
        when "refresh_token" then answer(refreshed, UNUSABLE_REFRESH_TOKEN)
        else refuse("unsupported_grant_type", "The token address takes authorization_code or refresh_token")
        end
      end

      private

      def answer(tokens, refusal)
        return refuse("invalid_grant", refusal) unless tokens

        render json: { access_token: tokens.access_token, token_type: "Bearer", expires_in: Connection::LIFETIME.to_i, refresh_token: tokens.refresh_token }
      end

      def refuse(error, description) = render(status: :bad_request, json: { error: error, error_description: description })

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
