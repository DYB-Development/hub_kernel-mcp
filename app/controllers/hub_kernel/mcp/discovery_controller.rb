module HubKernel
  module Mcp
    class DiscoveryController < ActionController::API
      def resource = render(json: { resource: endpoint_url, authorization_servers: [ request.base_url ] })

      def sign_in
        render json: {
          issuer: request.base_url,
          registration_endpoint: "#{endpoint_url}/register",
          authorization_endpoint: "#{endpoint_url}/authorize",
          token_endpoint: "#{endpoint_url}/token",
          response_types_supported: [ "code" ],
          grant_types_supported: [ "authorization_code", "refresh_token" ],
          token_endpoint_auth_methods_supported: [ "none" ],
          code_challenge_methods_supported: [ "S256" ]
        }
      end

      private

      def endpoint_url = request.base_url + HubKernel::Mcp::Engine.routes.find_script_name({})
    end
  end
end
