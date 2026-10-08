require "digest"
require "securerandom"

module HubKernel
  module Mcp
    class Connection < ActiveRecord::Base
      LIFETIME = 1.hour
      REFRESH_LIFETIME = 90.days

      Tokens = Data.define(:access_token, :refresh_token)

      belongs_to :client

      def self.issue(person:, client:)
        tokens = Tokens.new(access_token: SecureRandom.urlsafe_base64(32), refresh_token: SecureRandom.urlsafe_base64(32))
        create!(token_digest: digest(tokens.access_token), refresh_token_digest: digest(tokens.refresh_token), person_gid: person.to_global_id.to_s, client: client, expires_at: LIFETIME.from_now, refresh_expires_at: REFRESH_LIFETIME.from_now)
        tokens
      end

      def self.person_for(token) = where(expires_at: Time.current..).find_by(token_digest: digest(token.to_s))&.person

      def self.digest(token) = Digest::SHA256.hexdigest(token)

      def person = GlobalID::Locator.locate(person_gid)
    end
  end
end
