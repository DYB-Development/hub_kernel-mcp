require "uri"

module HubKernel
  module Mcp
    class Client < ActiveRecord::Base
      LOCAL_HOSTS = %w[localhost 127.0.0.1 ::1].freeze

      has_secure_token :uid

      validate :redirect_uris_named, :redirect_uris_allowed

      private

      def redirect_uris_named
        errors.add(:base, "A client must register at least one redirect address") if redirect_uris.blank?
      end

      def redirect_uris_allowed
        Array(redirect_uris).reject { |address| allowed_redirect?(address.to_s) }.each do |address|
          errors.add(:base, "#{address} is neither HTTPS nor on the client's own machine")
        end
      end

      def allowed_redirect?(address)
        uri = URI.parse(address)
        uri.hostname.present? && (uri.scheme == "https" || (uri.scheme == "http" && LOCAL_HOSTS.include?(uri.hostname)))
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
