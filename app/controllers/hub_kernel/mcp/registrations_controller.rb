module HubKernel
  module Mcp
    class RegistrationsController < ActionController::API
      def create
        client = Client.create!(name: params[:client_name], redirect_uris: Array(params[:redirect_uris]))
        render status: :created, json: { client_id: client.uid, client_name: client.name, redirect_uris: client.redirect_uris, token_endpoint_auth_method: "none" }
      end
    end
  end
end
