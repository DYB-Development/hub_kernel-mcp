require "uri"

module HubKernel
  module Mcp
    class AuthorizationsController < HubKernel::Mcp.browser_controller.constantize
      APPROVAL_PARAMS = %i[response_type client_id redirect_uri state code_challenge code_challenge_method].freeze

      layout -> { HubKernel::Mcp.browser_layout }

      before_action { send(HubKernel::Mcp.sign_in_method) }
      before_action :refuse_unregistered_redirect

      helper_method :approval_params

      def new
      end

      def create
        return redirect_to_client(error: "access_denied") unless params[:decision] == "approve"

        code = AuthorizationCode.issue(person: send(HubKernel::Mcp.browser_person_method), client: @client, redirect_uri: params[:redirect_uri], code_challenge: params[:code_challenge])
        redirect_to_client(code: code)
      end

      private

      def refuse_unregistered_redirect
        @client = Client.find_by(uid: params[:client_id])
        render :unregistered_redirect, status: :bad_request unless @client&.redirect_uris&.include?(params[:redirect_uri])
      end

      def redirect_to_client(answer)
        uri = URI.parse(params[:redirect_uri])
        uri.query = [ uri.query, answer.merge(state: params[:state]).compact.to_query ].compact_blank.join("&")
        redirect_to uri.to_s, allow_other_host: true
      end

      def approval_params = params.permit(*APPROVAL_PARAMS)
    end
  end
end
