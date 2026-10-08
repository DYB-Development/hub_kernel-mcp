require "uri"

module HubKernel
  module Mcp
    class AuthorizationsController < HubKernel::Mcp.browser_controller.constantize
      APPROVAL_PARAMS = %i[response_type client_id redirect_uri state code_challenge code_challenge_method].freeze

      layout -> { HubKernel::Mcp.browser_layout }

      before_action { send(HubKernel::Mcp.sign_in_method) }
      around_action :report_unexpected_errors
      before_action :refuse_missing_values, :refuse_unknown_client, :refuse_unregistered_redirect
      before_action :refuse_without_pkce

      helper_method :approval_params

      def new
      end

      def create
        return redirect_to_client(error: "access_denied") unless params[:decision] == "approve"

        code = AuthorizationCode.issue(person: send(HubKernel::Mcp.browser_person_method), client: @client, redirect_uri: params[:redirect_uri], code_challenge: params[:code_challenge])
        redirect_to_client(code: code)
      end

      private

      def report_unexpected_errors
        yield
      rescue StandardError => error
        Rails.error.report(error, handled: true)
        @reason = "Signing in failed unexpectedly"
        render :refused, status: :internal_server_error
      end

      def refuse_missing_values
        missing = %i[client_id redirect_uri].find { |name| params[name].blank? }
        refuse_on_page("The approval request is missing #{missing}") if missing
      end

      def refuse_unknown_client
        @client = Client.find_by(uid: params[:client_id])
        refuse_on_page("The app asking to connect is not registered") unless @client
      end

      def refuse_unregistered_redirect
        refuse_on_page("This app asked to send you to an address it did not register") unless @client.redirect_uris.include?(params[:redirect_uri])
      end

      def refuse_on_page(reason)
        @reason = reason
        render :refused, status: :bad_request
      end

      def refuse_without_pkce
        redirect_to_client(error: "invalid_request", error_description: "A PKCE challenge using S256 is required") unless params[:code_challenge].present? && params[:code_challenge_method] == "S256"
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
