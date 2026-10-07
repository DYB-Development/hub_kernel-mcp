# hub_kernel-mcp

Serves the methods every hub a host serves exposes as MCP tools, at one address. Every
request goes through the host's own sign-in, then hub_kernel's permission check and account
scope.

## Usage

Add the gem, then in an initializer name the controller the endpoint inherits from and the two
methods on it that give the person and the account a request is made for:

```ruby
HubKernel::Mcp.base_controller = "Api::HubBaseController"
HubKernel::Mcp.person_method = :current_person
HubKernel::Mcp.account_method = :current_account
```

The hubs served are the host's one list in hub_kernel-interface, which every interface gem
serves:

```ruby
Rails.application.config.to_prepare do
  HubKernel::Interface.hubs = [ Supplies, { "money" => Billing::Ledger } ]
end
```

Mount the engine:

```ruby
mount HubKernel::Mcp::Engine => "/mcp"
```

The endpoint takes MCP's JSON-RPC requests by POST. `initialize` answers the server's name,
its version, a tools capability, and the protocol version the client asked for when the gem
supports it, or else the newest it does: 2025-11-25, 2025-06-18, 2025-03-26 or 2024-11-05. A
notification is accepted with no answer.

`tools/list` returns one tool for each method the caller may call, across every served hub.
Each tool is named `<hub>__<method>`, where the hub part is the name the hub is served at, and
its input schema names the values the method takes:

```json
{ "name": "supplies__price_of", "inputSchema": { "type": "object", "properties": { "item": {} } } }
```

`tools/call` runs the hub method a tool names, for the person and account the host's methods
give, and returns the method's answer as JSON text:

```json
{ "content": [ { "type": "text", "text": "\"soap costs 3\"" } ], "isError": false }
```

A hub's refusal, or a value the method requires and the call left out, comes back as a tool
error carrying the reason, with `isError` set. A tool the caller may not call, a tool that does
not exist, and a tool naming a hub the host does not serve are all answered with the same
JSON-RPC error, code -32602, `Unknown tool: <name>`.

A caller the host's sign-in refuses is refused before any hub is asked.

## Installation

```ruby
gem "hub_kernel-mcp"
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
