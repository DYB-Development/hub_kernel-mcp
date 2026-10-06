module HubKernel
  module Mcp
    class MessagesController < HubKernel::Mcp.base_controller.constantize
      def create
        render json: { jsonrpc: "2.0", id: params[:id], result: initialized }
      end

      private

      def initialized = { protocolVersion: protocol_version, serverInfo: { name: "hub_kernel-mcp", version: HubKernel::Mcp::VERSION }, capabilities: { tools: {} } }

      def protocol_version = params.dig(:params, :protocolVersion)
    end
  end
end
