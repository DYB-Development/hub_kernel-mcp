require "rack/request"

module HubKernel
  module Mcp
    class Challenge
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        headers["www-authenticate"] = challenge(Rack::Request.new(env)) if status == 401
        [ status, headers, body ]
      end

      private

      def challenge(request) = %(Bearer resource_metadata="#{request.base_url}/.well-known/oauth-protected-resource#{request.script_name}")
    end
  end
end
