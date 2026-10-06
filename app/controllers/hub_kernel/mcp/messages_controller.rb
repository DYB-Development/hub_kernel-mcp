module HubKernel
  module Mcp
    class MessagesController < HubKernel::Mcp.base_controller.constantize
      PROTOCOL_VERSIONS = %w[2025-11-25 2025-06-18 2025-03-26 2024-11-05].freeze

      def create
        return head :accepted unless params.key?(:id)

        render json: { jsonrpc: "2.0", id: params[:id], result: initialized }
      end

      private

      def initialized = { protocolVersion: protocol_version, serverInfo: { name: "hub_kernel-mcp", version: HubKernel::Mcp::VERSION }, capabilities: { tools: {} } }

      def protocol_version = PROTOCOL_VERSIONS.include?(params.dig(:params, :protocolVersion)) ? params.dig(:params, :protocolVersion) : PROTOCOL_VERSIONS.first
    end
  end
end
