module HubKernel
  module Mcp
    class DiscoveryController < ActionController::API
      def resource = render(json: { resource: endpoint_url, authorization_servers: [ request.base_url ] })

      private

      def endpoint_url = request.base_url + HubKernel::Mcp::Engine.routes.find_script_name({})
    end
  end
end
