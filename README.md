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
`invalid_redirect_uri`, and the reason. A body that is not valid JSON is answered with status
400 and `invalid_client_metadata`. One address may register ten clients an hour, and a
registration past that is answered with status 429 and `too_many_registrations`. A host sets a
different limit with:

```ruby
HubKernel::Mcp.registration_limit = 20
```

The approval address is a browser page. It runs inside a controller of the host's, so the
host's own sign-in decides who is approving. Name that controller, the method on it that signs a
person in, the method that gives the signed-in person, and the layout the page is shown in:

```ruby
HubKernel::Mcp.browser_controller = "ApplicationController"
HubKernel::Mcp.sign_in_method = :authenticate_user!
HubKernel::Mcp.browser_person_method = :current_user
HubKernel::Mcp.browser_layout = "application"
```

`HubKernel::Mcp.check!` names each of the four a host has not set. The person the page gives is
kept by its global id, so it must be a record that has one.

A person who is not signed in is sent through the host's sign-in. A signed-in person sees the
name of the app asking to connect, with an Approve and a Deny button. Approving sends them back
to the client's redirect address with a code and the client's `state`. Denying sends them back
with `error=access_denied` and no code. A request missing its `client_id` or `redirect_uri`,
naming a client that is not registered, or naming a redirect address the client did not
register shows an error page saying which, and sends the person nowhere. A request with no PKCE
challenge, or one whose method is not `S256`, is sent back with `error=invalid_request`.

The client trades the code at the token address, posting it form-encoded with its PKCE verifier,
the redirect address it was approved for and its client id:

```
grant_type=authorization_code&code=<code>&code_verifier=<verifier>&redirect_uri=<redirect>&client_id=<client id>
```

It is answered with an access token that lasts an hour and a refresh token:

```json
{ "access_token": "<token>", "token_type": "Bearer", "expires_in": 3600, "refresh_token": "<refresh token>" }
```

A code is used up by the trade. A code posted with a verifier that does not match its challenge,
with another client id or redirect address, a second time, or more than ten minutes after it was
made is answered with status 400, `invalid_grant` and a description, and gives no token. A code
posted a second time also stops the access and refresh tokens already issued from it.

When the access token expires, the client posts its refresh token and client id to the same
address:

```
grant_type=refresh_token&refresh_token=<refresh token>&client_id=<client id>
```

It is answered the same way, with a new access token and a new refresh token, and the refresh
token it posted stops working. A refresh token posted by a client other than the one it was
issued to, one already traded, or one unused for ninety days is answered with status 400,
`invalid_grant` and a description, and the person signs in again. Any other `grant_type` is
answered with `unsupported_grant_type`, and a body that cannot be read with `invalid_request`.

An unexpected error at the registration or token address or a discovery document is answered
with status 500 and `server_error`, and on the approval page with an error page. Its message is
never sent to the client or shown to the person. It is reported to the host app's error
reporting through `Rails.error`.

The client then sends the token on every request to the endpoint as `Authorization: Bearer
<token>`. The host's own sign-in, the base controller the endpoint inherits from, asks the gem
for the person a token acts for:

```ruby
class Api::McpBaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action { head :unauthorized unless current_person }

  private

  def current_person = authenticate_with_http_token { |token| HubKernel::Mcp::Connection.person_for(token) }
end
```

`HubKernel::Mcp::Connection.person_for` gives the person while the token is unexpired, and `nil`
for an expired or unknown token. Every call is made in the account the host's account method
gives, so that method must give one for a person signed in this way.

A person can see the apps connected as them and disconnect one. The gem ships a section for a
host's settings page: the `hub_kernel/mcp/connections` partial, which lists each of the person's
connections with the app's name, when it connected and when it was last used, and the
`HubKernel::Mcp::Disconnect` action its Disconnect buttons run. A host using settings_hub
registers both:

```ruby
SettingsHub.section :connections, area: :user, title: "Connected apps",
  renders: "hub_kernel/mcp/connections", runs: "HubKernel::Mcp::Disconnect"
```

The partial takes the `person` and the `submit_url` its buttons send a `connection_id` to by
PATCH. The action is built with `new(person:, account:, values:)`, and `call` answers a result
whose `ok?` is false, with a `message`, when the connection is not the person's own. A
disconnected connection's access and refresh tokens stop working at once.

A host runs one task, on whatever schedule its job runner keeps, to remove sign-in records that
can no longer be used: authorization codes past their ten minutes, connections whose access and
refresh tokens have both expired, and clients over a day old with no connection.

```sh
bin/rails hub_kernel_mcp:prune
```

A connection whose access token or refresh token still works is never removed.

## Installation

```ruby
gem "hub_kernel-mcp"
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
