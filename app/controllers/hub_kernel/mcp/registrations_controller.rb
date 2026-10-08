module HubKernel
  module Mcp
    class RegistrationsController < ActionController::API
      rescue_from(StandardError) do |error|
        Rails.error.report(error, handled: true)
        render status: :internal_server_error, json: { error: "server_error", error_description: "The sign-in failed unexpectedly" }
      end
      rescue_from(ActionDispatch::Http::Parameters::ParseError) { render(status: :bad_request, json: { error: "invalid_client_metadata", error_description: "The registration body is not valid JSON" }) }

      def create
        return refuse_past_limit if Client.where(registered_from: request.remote_ip, created_at: 1.hour.ago..).count >= HubKernel::Mcp.registration_limit

        client = Client.new(name: params[:client_name], redirect_uris: Array(params[:redirect_uris]), registered_from: request.remote_ip)
        return refuse(client) unless client.save

        render status: :created, json: { client_id: client.uid, client_name: client.name, redirect_uris: client.redirect_uris, token_endpoint_auth_method: "none" }
      end

      private

      def refuse_past_limit
        render status: :too_many_requests, json: { error: "too_many_registrations", error_description: "This address has registered #{HubKernel::Mcp.registration_limit} clients in the last hour, which is the limit" }
      end

      def refuse(client) = render(status: :bad_request, json: { error: "invalid_redirect_uri", error_description: client.errors.full_messages.to_sentence })
    end
  end
end
