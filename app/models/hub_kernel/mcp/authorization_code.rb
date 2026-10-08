require "base64"
require "digest"
require "securerandom"

module HubKernel
  module Mcp
    class AuthorizationCode < ActiveRecord::Base
      LIFETIME = 10.minutes

      belongs_to :client

      def self.issue(person:, client:, redirect_uri:, code_challenge:)
        code = SecureRandom.urlsafe_base64(32)
        create!(code_digest: digest(code), person_gid: person.to_global_id.to_s, client: client, redirect_uri: redirect_uri, code_challenge: code_challenge, expires_at: LIFETIME.from_now)
        code
      end

      def self.digest(code) = Digest::SHA256.hexdigest(code)

      def person = GlobalID::Locator.locate(person_gid)

      def verifies?(verifier)
        ActiveSupport::SecurityUtils.secure_compare(Base64.urlsafe_encode64(Digest::SHA256.digest(verifier.to_s), padding: false), code_challenge)
      end
    end
  end
end
