require "test_helper"

class HubKernel::Mcp::PruneTest < ActiveSupport::TestCase
  setup { @client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ]) }

  test "pruning removes codes past their ten minutes and keeps the rest" do
    issue_code
    travel 11.minutes
    kept = issue_code

    HubKernel::Mcp::Prune.call

    assert_equal [ HubKernel::Mcp::AuthorizationCode.digest(kept) ], HubKernel::Mcp::AuthorizationCode.pluck(:code_digest)
  end

  test "pruning removes connections that can no longer be used and keeps one whose refresh token still works" do
    HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    HubKernel::Mcp::Connection.issue(person: Person.new("alex"), client: @client)
    HubKernel::Mcp::Connection.of(Person.new("alex")).update_all(refresh_token_digest: nil, refresh_expires_at: nil)
    travel 89.days
    HubKernel::Mcp::Connection.issue(person: Person.new("kim"), client: @client)
    travel 2.days

    HubKernel::Mcp::Prune.call

    assert_equal [ Person.new("kim") ], HubKernel::Mcp::Connection.all.map(&:person)
  end

  test "pruning removes clients with no connection older than a day and keeps the rest" do
    HubKernel::Mcp::Client.create!(name: "Abandoned", redirect_uris: [ "https://claude.ai/callback" ])
    HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: @client)
    travel 1.day + 1.second
    HubKernel::Mcp::Client.create!(name: "New", redirect_uris: [ "https://claude.ai/callback" ])

    HubKernel::Mcp::Prune.call

    assert_equal [ "Claude", "New" ], HubKernel::Mcp::Client.order(:name).pluck(:name)
  end

  private

  def issue_code = HubKernel::Mcp::AuthorizationCode.issue(person: Person.new("sam"), client: @client, redirect_uri: "https://claude.ai/callback", code_challenge: "challenge")
end
