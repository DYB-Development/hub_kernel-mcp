require "uri"

module HubKernel
  module Mcp
    class AuthorizationsController < HubKernel::Mcp.browser_controller.constantize
      APPROVAL_PARAMS = %i[response_type client_id redirect_uri state code_challenge code_challenge_method].freeze

      layout -> { HubKernel::Mcp.browser_layout }

      before_action { send(HubKernel::Mcp.sign_in_method) }

      helper_method :approval_params

      def new
        @client = Client.find_by!(uid: params[:client_id])
      end

      def create
        client = Client.find_by!(uid: params[:client_id])
        return redirect_to_client(error: "access_denied") unless params[:decision] == "approve"

        code = AuthorizationCode.issue(person: send(HubKernel::Mcp.browser_person_method), client: client, redirect_uri: params[:redirect_uri], code_challenge: params[:code_challenge])
        redirect_to_client(code: code)
      end

      private

      def redirect_to_client(answer)
        uri = URI.parse(params[:redirect_uri])
        uri.query = [ uri.query, answer.merge(state: params[:state]).compact.to_query ].compact_blank.join("&")
        redirect_to uri.to_s, allow_other_host: true
      end

      def approval_params = params.permit(*APPROVAL_PARAMS)
    end
  end
end
