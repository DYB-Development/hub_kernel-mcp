require "test_helper"

class ConnectionsSectionTest < ActiveSupport::TestCase
  setup do
    travel_to Time.utc(2026, 10, 8, 9, 30)
    claude = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    other = HubKernel::Mcp::Client.create!(name: "Other", redirect_uris: [ "https://other.example/callback" ])
    @tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: claude)
    HubKernel::Mcp::Connection.issue(person: Person.new("alex"), client: other)
  end

  test "a person's connections are listed with the app's name, when it connected and when it was last used" do
    travel 20.minutes
    HubKernel::Mcp::Connection.person_for(@tokens.access_token)

    assert_equal [ "Claude Connected October 08, 2026 09:30 Last used October 08, 2026 09:50 Disconnect" ], section_for(Person.new("sam")).css("li").map { |item| item.text.squish }
  end

  private

  def section_for(person)
    Nokogiri::HTML.fragment(ApplicationController.render(partial: "hub_kernel/mcp/connections", locals: { person: person, account: "acme", selection: {}, submit_url: "/settings/connections" }))
  end
end
