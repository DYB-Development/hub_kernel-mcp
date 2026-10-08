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

      private

      def approval_params = params.permit(*APPROVAL_PARAMS)
    end
  end
end
