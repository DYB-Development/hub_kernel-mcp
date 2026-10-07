module HubKernel
  module Mcp
    class MessagesController < HubKernel::Mcp.base_controller.constantize
      UnknownTool = Class.new(StandardError)

      PROTOCOL_VERSIONS = %w[2025-11-25 2025-06-18 2025-03-26 2024-11-05].freeze

      def create
        return head :accepted unless params.key?(:id)

        render json: { jsonrpc: "2.0", id: params[:id], result: answer }
      rescue UnknownTool, HubKernel::UnexposedMethodError, HubKernel::NotAllowed
        render json: { jsonrpc: "2.0", id: params[:id], error: { code: -32602, message: "Unknown tool: #{tool_name}" } }
      end

      private

      def answer
        case params[:method]
        when "initialize" then initialized
        when "tools/list" then { tools: tools }
        when "tools/call" then called
        end
      end

      def initialized = { protocolVersion: protocol_version, serverInfo: { name: "hub_kernel-mcp", version: HubKernel::Mcp::VERSION }, capabilities: { tools: {} } }

      def protocol_version = PROTOCOL_VERSIONS.include?(params.dig(:params, :protocolVersion)) ? params.dig(:params, :protocolVersion) : PROTOCOL_VERSIONS.first

      def tools
        HubKernel::Interface.served.flat_map do |served_name, hub|
          hub.exposures_for(person: caller_person, account: caller_account).map { |exposure| tool(served_name, exposure) }
        end
      end

      def tool(served_name, exposure) = { name: "#{served_name}__#{exposure.name}", inputSchema: { type: "object", properties: exposure.takes.index_with { {} } } }

      def called
        served_name, method_name = tool_name.split("__", 2)
        hub = HubKernel::Interface.find(served_name) || raise(UnknownTool)
        answer = hub.call_exposed(method_name, values: arguments, person: caller_person, account: caller_account)
        { content: [ { type: "text", text: answer.to_json } ], isError: false }
      rescue HubKernel::Refused, HubKernel::MissingArgumentError => refusal
        { content: [ { type: "text", text: refusal.message } ], isError: true }
      end

      def tool_name = params.dig(:params, :name).to_s

      def arguments = params.dig(:params, :arguments)&.to_unsafe_h.to_h.deep_symbolize_keys

      def caller_person = send(HubKernel::Mcp.person_method)

      def caller_account = send(HubKernel::Mcp.account_method)
    end
  end
end
