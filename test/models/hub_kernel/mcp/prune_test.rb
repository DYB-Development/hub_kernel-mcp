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

  private

  def issue_code = HubKernel::Mcp::AuthorizationCode.issue(person: Person.new("sam"), client: @client, redirect_uri: "https://claude.ai/callback", code_challenge: "challenge")
end
