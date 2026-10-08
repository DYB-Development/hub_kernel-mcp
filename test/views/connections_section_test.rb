require "test_helper"

class ConnectionsSectionTest < ActionView::TestCase
  helper KeystoneUiHelper

  setup do
    travel_to Time.utc(2026, 10, 8, 9, 30)
    claude = HubKernel::Mcp::Client.create!(name: "Claude", redirect_uris: [ "https://claude.ai/callback" ])
    other = HubKernel::Mcp::Client.create!(name: "Other", redirect_uris: [ "https://other.example/callback" ])
    @tokens = HubKernel::Mcp::Connection.issue(person: Person.new("sam"), client: claude)
    HubKernel::Mcp::Connection.issue(person: Person.new("alex"), client: other)
  end

  test "a person's connections are rows of a keystone table naming the app, when it connected and when it was last used" do
    travel 20.minutes
    HubKernel::Mcp::Connection.person_for(@tokens.access_token)

    assert_equal [ [ "Claude", "October 08, 2026 09:30", "October 08, 2026 09:50" ] ], section_for(Person.new("sam")).css(".ks-table tbody tr").map { |row| row.css("td").first(3).map { |cell| cell.text.squish } }
  end

  test "a connection's Disconnect menu item sends its id to the section's address by PATCH" do
    form = section_for(Person.new("sam")).at_css(".ks-table tbody form")

    assert_equal [ "/settings/connections?connection_id=#{HubKernel::Mcp::Connection.of(Person.new("sam")).sole.id}", "patch", "Disconnect" ], [ form["action"], form.at_css("input[name=_method]")["value"], form.at_css("button").text.squish ]
  end

  test "a person with no connected apps is told so in the table" do
    assert_equal [ "No apps are connected." ], section_for(Person.new("kim")).css(".ks-table tbody td").map { |cell| cell.text.squish }
  end

  test "the table sits under a keystone section titled Connected apps" do
    assert_equal [ "Connected apps" ], section_for(Person.new("sam")).css("h2.ks-section-title").map(&:text)
  end

  private

  def section_for(person)
    Nokogiri::HTML.fragment(render(partial: "hub_kernel/mcp/connections", locals: { person: person, account: "acme", selection: {}, submit_url: "/settings/connections" }))
  end
end
