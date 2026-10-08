module HubKernel
  module Mcp
    class AuthorizationsController < HubKernel::Mcp.browser_controller.constantize
      layout -> { HubKernel::Mcp.browser_layout }

      before_action { send(HubKernel::Mcp.sign_in_method) }

      def new
      end
    end
  end
end
