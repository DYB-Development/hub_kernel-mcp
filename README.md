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
  HubKernel::Mcp.check!
end
```

`HubKernel::Mcp.check!` raises `HubKernel::Mcp::UnservableHubError` naming every problem
in one error. It names each problem hub_kernel-interface's own check finds in the served
list, a served name holding two underscores in a row, and a tool whose name holds a
character other than a letter, a digit, an underscore or a hyphen or is longer than 64
characters. Inside `to_prepare` it runs again after every code reload.

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
{
  "name": "supplies__price_of",
  "description": "Reads data from the supplies hub.",
  "inputSchema": { "type": "object", "properties": { "item": {} } },
  "annotations": { "readOnlyHint": true }
}
```

A tool for a method that writes has `readOnlyHint` set to false and a description saying it
changes data, so a client can ask before it calls one.

`tools/call` runs the hub method a tool names, for the person and account the host's methods
give, and returns the method's answer as JSON text:

```json
{ "content": [ { "type": "text", "text": "\"soap costs 3\"" } ], "isError": false }
```

A hub's refusal, a value the method requires and the call left out, a value the method is not
listed with, and a record the call names that does not exist each come back as a tool error
carrying the reason, with `isError` set. The last two reasons come from hub_kernel-interface, so
they read the same in every interface gem, such as `price_of does not take colour` and
`No item has the id 9`. A tool the caller may not call, a tool that does not exist, and a tool
naming a hub the host does not serve are all answered with the same JSON-RPC error, code
-32602, `Unknown tool: <name>`, whatever values the call sends.

A caller the host's sign-in refuses is refused before any hub is asked.

## Signing in from a connector screen

A client such as Claude's connector screen finds the endpoint's sign-in by itself and
registers there, so a person only pastes the endpoint's address. Install the gem's migrations,
then mount its discovery documents at the site root beside the endpoint:

```sh
bin/rails hub_kernel_mcp:install:migrations db:migrate
```

```ruby
mount HubKernel::Mcp::Engine => "/mcp"
mount HubKernel::Mcp::Discovery => "/.well-known"
```

Every 401 from the endpoint carries a `WWW-Authenticate` header naming where the endpoint is
described:

```
Bearer resource_metadata="https://example.com/.well-known/oauth-protected-resource/mcp"
```

That document names the endpoint's address and its sign-in, the site root. The sign-in's own
document, at `/.well-known/oauth-authorization-server`, names the registration, approval and
token addresses under the endpoint's address, such as `/mcp/register`, and says a client must
use PKCE with SHA-256.

A client registers by posting its name and redirect addresses to the registration address:

```json
{ "client_name": "Claude", "redirect_uris": [ "https://claude.ai/api/mcp/auth_callback" ] }
```

It is answered with status 201 and a client id. A registration with no redirect address, or
with one that is neither HTTPS nor on the client's own machine, is answered with status 400,
`invalid_redirect_uri`, and the reason.

A `ping` is answered with an empty result. Every other request the endpoint cannot answer gets
a JSON-RPC error:

| Request | Code | Message |
|---|---|---|
| A body that is not valid JSON | -32700 | `Parse error` |
| A body that is not one JSON-RPC request, such as a batch | -32600 | `Invalid Request` |
| An MCP method the endpoint does not support | -32601 | `Method not found: <method>` |
| An unexpected error inside a hub method | -32603 | `Internal error` |

An unexpected error's own message is never sent to the client. It is reported to the host
app's error reporting through `Rails.error`. A GET to the endpoint's address is answered with
status 405, since the endpoint offers no sessions or server-sent events.

## Installation

```ruby
gem "hub_kernel-mcp"
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
