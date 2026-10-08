module HubKernel
  module Mcp
    class RegistrationsController < ActionController::API
      def create
        client = Client.new(name: params[:client_name], redirect_uris: Array(params[:redirect_uris]))
        return refuse(client) unless client.save

        render status: :created, json: { client_id: client.uid, client_name: client.name, redirect_uris: client.redirect_uris, token_endpoint_auth_method: "none" }
      end

      private

      def refuse(client) = render(status: :bad_request, json: { error: "invalid_redirect_uri", error_description: client.errors.full_messages.to_sentence })
    end
  end
end
