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

      def tool(served_name, exposure) = { name: "#{served_name}__#{exposure.name}", description: description(served_name, exposure), inputSchema: { type: "object", properties: exposure.takes.index_with { {} } }, annotations: { readOnlyHint: !exposure.writes } }

      def called
        served_name, method_name = tool_name.split("__", 2)
        hub = HubKernel::Interface.find(served_name) || raise(UnknownTool)
        raise UnknownTool unless hub.exposed(method_name)
        HubKernel::Interface::CallReasons.refuse_unlisted_values(hub, method_name, values: arguments, person: caller_person, account: caller_account)
        answer = hub.call_exposed(method_name, values: arguments, person: caller_person, account: caller_account)
        { content: [ { type: "text", text: answer.to_json } ], isError: false }
      rescue HubKernel::Refused, HubKernel::MissingArgumentError => refusal
        tool_error(refusal.message)
      rescue ActiveRecord::RecordNotFound => missing
        tool_error(HubKernel::Interface::CallReasons.missing_record(missing))
      end

      def tool_error(reason) = { content: [ { type: "text", text: reason } ], isError: true }

      def tool_name = params.dig(:params, :name).to_s

      def arguments = params.dig(:params, :arguments)&.to_unsafe_h.to_h.deep_symbolize_keys

      def description(served_name, exposure) = exposure.writes ? "Changes data in the #{served_name} hub." : "Reads data from the #{served_name} hub."

      def caller_person = send(HubKernel::Mcp.person_method)

      def caller_account = send(HubKernel::Mcp.account_method)
    end
  end
end
