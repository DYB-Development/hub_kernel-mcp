module HubKernel
  module Mcp
    class MessagesController < HubKernel::Mcp.base_controller.constantize
      PROTOCOL_VERSIONS = %w[2025-11-25 2025-06-18 2025-03-26 2024-11-05].freeze

      def create
        return head :accepted unless params.key?(:id)

        render json: { jsonrpc: "2.0", id: params[:id], result: answer }
      end

      private

      def answer
        case params[:method]
        when "initialize" then initialized
        when "tools/list" then { tools: tools }
        end
      end

      def initialized = { protocolVersion: protocol_version, serverInfo: { name: "hub_kernel-mcp", version: HubKernel::Mcp::VERSION }, capabilities: { tools: {} } }

      def protocol_version = PROTOCOL_VERSIONS.include?(params.dig(:params, :protocolVersion)) ? params.dig(:params, :protocolVersion) : PROTOCOL_VERSIONS.first

      def tools
        HubKernel::Interface.served.flat_map do |served_name, hub|
          hub.exposures_for(person: caller_person, account: caller_account).map { |exposure| { name: "#{served_name}__#{exposure.name}" } }
        end
      end

      def caller_person = send(HubKernel::Mcp.person_method)

      def caller_account = send(HubKernel::Mcp.account_method)
    end
  end
end
