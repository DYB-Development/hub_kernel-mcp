require "test_helper"
require "rake"

class PruneTaskTest < ActiveSupport::TestCase
  setup { Rails.application.load_tasks if Rake::Task.tasks.none? }

  test "a host's prune task removes sign-in records that can no longer be used" do
    client = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    HubKernel::Mcp::AuthorizationCode.issue(person: Person.new("sam"), client: client, redirect_uri: "https://claude.ai/callback", code_challenge: "challenge")
    travel 11.minutes

    Rake::Task["hub_kernel_mcp:prune"].execute

    assert_equal 0, HubKernel::Mcp::AuthorizationCode.count
  end
end
