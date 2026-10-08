---
name: hub_kernel-mcp-develop
description: Use PROACTIVELY for calling a host's hub methods over MCP — connecting an MCP client to the endpoint, finding the endpoint's sign-in from a 401's WWW-Authenticate header and the two .well-known discovery documents, registering a client at the registration address, sending a person to the approval page and handling the code or error it sends back, trading that code with its PKCE verifier for an access token and a refresh token at the token address, trading a refresh token for a new pair when the access token expires, sending the access token on every request, sending initialize and ping, listing the tools a signed-in person may call with tools/list, calling one with tools/call, handling its tool errors and JSON-RPC errors, and reading the apps a person has connected, with when each connected and was last used — MUST BE USED instead of hand-rolling a JSON API, an MCP server, OAuth discovery documents, client registration, an OAuth approval page, an OAuth token endpoint, an OAuth refresh exchange or a query for a person's connected apps for the host's hubs.
tools: Read, Write, Edit, Grep
scope: hub MCP tools — serving the methods every hub a host serves, from hub_kernel-interface's one served list, as MCP tools at one JSON-RPC endpoint in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope, with a boot check for hubs that cannot be served as tools, the OAuth discovery documents, 401 challenge and client registration that let a client such as Claude's connector screen find the endpoint's sign-in and register by itself, and the approval page where a person signed in to the host through the browser approves that client and is issued an authorization code, the token exchange that trades that code with its PKCE verifier for an access token lasting an hour and a refresh token, the refresh exchange that trades a refresh token for a new access token and a new refresh token and retires the one posted, and the lookup a host's sign-in calls to get the person a bearer token acts for, which records when the connection was last used, and the settings section a host registers with settings_hub that lists a person's connections with the app's name, when it connected and when it was last used, and disconnects one that is the person's own
---

This local writes the code or configuration that talks to a host's hub_kernel-mcp
endpoint, following these steps exactly. Where a step names a decision, it asks
the developer and does not pick.

## What hub_kernel-mcp is

A JSON-RPC endpoint in a host Rails app that offers every method the host's hubs
expose as an MCP tool, for the person and account the host's sign-in gives. Beside
it, the host serves two discovery documents, a registration address, a browser
approval page and a token address, so a client such as Claude's connector screen
can find the endpoint's sign-in, register itself, have a person approve it, trade
the approval's code for an access token it sends on every request, and trade a
refresh token for a new access token when that one expires, from the endpoint's
address alone. Each approval the person gives is kept as a connection, which the
host's own code can read. Fire this local when code or a client needs to list or
call those tools, find or register with the endpoint's sign-in, send a person to
approve a client, trade a code or a refresh token for tokens, read a person's
connections, or when a test needs to send requests to any of these addresses.

## Interface

- `POST /` — the endpoint, at the path the host serves it under, such as `/mcp`.
  It takes one JSON-RPC 2.0 request per POST as a JSON body. A GET to the same
  path is answered with status 405 and `Allow: POST`.
- `initialize` — answers `protocolVersion`, `serverInfo` with name
  `hub_kernel-mcp` and the gem's version, and `capabilities: { tools: {} }`.
  `protocolVersion` is the one the client sent in `params.protocolVersion` when
  it is one of `2025-11-25`, `2025-06-18`, `2025-03-26` or `2024-11-05`, and
  `2025-11-25` otherwise.
- `ping` — answers an empty result, `{}`.
- `tools/list` — answers `{ tools: [...] }`, one tool for each hub method the
  signed-in person may call in their account, across every served hub.
- `tools/call` — runs the hub method a tool names with `params.arguments`, for
  the signed-in person and account, and answers the method's return value as
  JSON text.
- `POST /register` — registers a client under the endpoint's path, such as
  `/mcp/register`, from its `client_name` and `redirect_uris`, and answers its
  `client_id`. It needs no sign-in.
- `GET /authorize` — the approval page under the endpoint's path, such as
  `/mcp/authorize`, opened in a person's browser. It sends a person who is not
  signed in to the host through the host's sign-in, then shows the client's name
  with an Approve and a Deny button.
- `POST /authorize` — the approval page's answer. It sends the browser back to
  the client's redirect address with a `code` and the client's `state` on
  Approve, and with `error=access_denied` and the `state` on Deny.
- `POST /token` — the token address under the endpoint's path, such as
  `/mcp/token`. It trades an approval's `code`, with the `redirect_uri` it was
  approved for and the PKCE `code_verifier`, for an access token lasting an hour
  and a refresh token. It needs no sign-in.
- `grant_type=refresh_token` — a `POST /token` that trades a refresh token and
  the `client_id` it was issued to for a new access token and a new refresh
  token, and stops the posted refresh token and the access token issued with it
  from working.
- `WWW-Authenticate` — the header on every 401 from the endpoint's path, naming
  the address of the endpoint's protected-resource document.
- `GET /.well-known/oauth-protected-resource` — answers the endpoint's address
  and its sign-in's address, the site root. It answers the same document with
  any path after it, such as `/.well-known/oauth-protected-resource/mcp`.
- `GET /.well-known/oauth-authorization-server` — answers the sign-in's
  document: its registration, approval and token addresses, and that a client
  must use PKCE with SHA-256.
- `HubKernel::Mcp::Connection.of` — takes a person record and answers an Active
  Record relation of that person's connections, one per approval they gave,
  each with its app's `client.name`, `created_at` and `last_used_at`.

## How to use it

1. Find the path the host serves the endpoint at in its `config/routes.rb`. If
   it is not there, stop and tell the developer the endpoint is not installed
   yet. For steps 3 to 8, also check that the routes serve the discovery
   documents at `/.well-known`. If they do not, stop and tell the developer the
   discovery documents are not installed yet.

2. Ask the developer how the client signs in. There are two ways, and the choice
   is theirs:

   - The client sends the host's own credential, such as a session cookie or a
     token header, with every request. Skip to step 9.
   - The client finds the sign-in by itself, registers, has a person approve
     it, trades the approval for an access token, and refreshes that token, as
     Claude's connector screen does. Follow steps 3 to 8.

3. Find the sign-in from a refused request. Send any request to the endpoint
   without a credential. When the host's sign-in refuses it with status 401, the
   answer carries this header, built from the site's address and the endpoint's
   path:

   ```
   WWW-Authenticate: Bearer resource_metadata="https://example.com/.well-known/oauth-protected-resource/mcp"
   ```

   The header is added only to a 401. A host whose sign-in refuses with another
   status, such as a redirect to a sign-in page, sends no header, so tell the
   developer the client cannot discover the sign-in on that host.

4. Read the two discovery documents. `GET` the address in `resource_metadata`:

   ```json
   { "resource": "https://example.com/mcp", "authorization_servers": [ "https://example.com" ] }
   ```

   Then `GET /.well-known/oauth-authorization-server` on the address in
   `authorization_servers`:

   ```json
   {
     "issuer": "https://example.com",
     "registration_endpoint": "https://example.com/mcp/register",
     "authorization_endpoint": "https://example.com/mcp/authorize",
     "token_endpoint": "https://example.com/mcp/token",
     "response_types_supported": [ "code" ],
     "grant_types_supported": [ "authorization_code", "refresh_token" ],
     "token_endpoint_auth_methods_supported": [ "none" ],
     "code_challenge_methods_supported": [ "S256" ]
   }
   ```

   Take every address from these documents, never build one by hand. A client
   must use the authorization code grant with a PKCE `S256` challenge, and it
   holds no client secret.

5. Register the client. Ask the developer for the client's name and every
   redirect address it will use, since both belong to the client. Each redirect
   address must be HTTPS, or plain HTTP on `localhost`, `127.0.0.1` or `::1`.
   POST them as JSON to `registration_endpoint`, with no credential:

   ```json
   { "client_name": "Claude", "redirect_uris": [ "https://claude.ai/api/mcp/auth_callback" ] }
   ```

   A registration is answered with status 201:

   ```json
   {
     "client_id": "<generated id>",
     "client_name": "Claude",
     "redirect_uris": [ "https://claude.ai/api/mcp/auth_callback" ],
     "token_endpoint_auth_method": "none"
   }
   ```

   Keep `client_id`. A registration with no redirect address, or with one that
   is not allowed, is answered with status 400:

   ```json
   { "error": "invalid_redirect_uri", "error_description": "<the reason for each address refused>" }
   ```

   Show `error_description` to the developer and do not retry with the same
   addresses.

6. Send the person to the approval page. Make a fresh random PKCE verifier and a
   fresh random `state` for this attempt, and keep both. The challenge is the
   verifier's SHA-256 digest, base64url-encoded with no padding. Open
   `authorization_endpoint` in the person's browser with these query values:

   ```
   https://example.com/mcp/authorize?response_type=code&client_id=<client_id>&redirect_uri=https%3A%2F%2Fclaude.ai%2Fapi%2Fmcp%2Fauth_callback&state=<state>&code_challenge=<challenge>&code_challenge_method=S256
   ```

   `redirect_uri` must be exactly one of the addresses registered in step 5.
   The page runs the host's own sign-in first, then shows the client's name and
   an Approve and a Deny button. The browser comes back to `redirect_uri` with
   the client's `state` added to any query the address already has:

   | Query back | When |
   |---|---|
   | `code=<code>&state=<state>` | The person approved. |
   | `error=access_denied&state=<state>` | The person denied. No code is sent. |
   | `error=invalid_request&error_description=...&state=<state>` | `code_challenge` was missing, or `code_challenge_method` was not `S256`. |

   Refuse any answer whose `state` is not the one sent. A `client_id` the host
   never registered, or a `redirect_uri` not registered for that client, is
   answered with status 400 and an error page, and the browser is sent nowhere,
   so the client hears nothing back. A code lasts 10 minutes and is tied to the
   person who approved, the client, the `redirect_uri` and the challenge.

7. Trade the code for an access token. POST it form-encoded to `token_endpoint`,
   with no credential, along with the verifier from step 6 and the same
   `redirect_uri`:

   ```
   grant_type=authorization_code&code=<code>&code_verifier=<verifier>&redirect_uri=https%3A%2F%2Fclaude.ai%2Fapi%2Fmcp%2Fauth_callback&client_id=<client_id>
   ```

   A trade is answered with status 200:

   ```json
   { "access_token": "<token>", "token_type": "Bearer", "expires_in": 3600, "refresh_token": "<refresh token>" }
   ```

   Keep `access_token` and `refresh_token` as secrets, since both act for the
   person who approved. A trade is answered with status 400 and
   `{ "error": "invalid_grant" }`, and gives no token, when the code is unknown,
   more than 10 minutes old, already traded, sent with a `client_id` other than
   the one it was approved for, sent with a `redirect_uri` other than the one
   approved, or sent with a verifier whose SHA-256 digest is not the challenge. A
   code is used up only by a trade that gives a token.

8. Refresh the access token when it expires after an hour. POST form-encoded to
   `token_endpoint`, with no credential, the refresh token last issued and the
   `client_id` from step 5:

   ```
   grant_type=refresh_token&refresh_token=<refresh token>&client_id=<client_id>
   ```

   A refresh is answered with status 200 and the same shape as step 7, holding a
   new `access_token` and a new `refresh_token`. Replace both stored tokens with
   the new ones at once. The refresh token posted stops working, and so does the
   access token issued with it, even if its hour has not passed. A refresh token
   lasts 90 days from when it was issued, and each refresh issues one that lasts
   another 90 days.

   A refresh is answered with status 400 and `{ "error": "invalid_grant" }`, and
   gives no token, when the refresh token is unknown, already used, more than 90
   days old, sent with a `client_id` other than the one it was issued to, or
   belongs to a connection the person has disconnected. Of
   two refreshes sent at once with the same refresh token, only one is answered
   with tokens. After an `invalid_grant`, go back to step 6 with a fresh verifier
   and `state`, and keep the `client_id` from step 5.

9. Send every request to the endpoint as a POST with a JSON body holding exactly
   one request, with the credential step 2 settled on. A client that followed
   steps 3 to 8 sends its access token as `Authorization: Bearer <access_token>`:

   ```json
   { "jsonrpc": "2.0", "id": 1, "method": "tools/list" }
   ```

   `jsonrpc` must be `"2.0"` and `method` must be a string. A batch, a JSON array
   of requests, is refused with -32600. A request with no `id` is a
   notification: it is answered with status 202 and no body, and nothing is run.
   A request the sign-in refuses gets the host's refusal, and no hub is asked. A
   401 for an access token means it has expired, was replaced by a refresh, was
   disconnected by the person, or is unknown, so refresh it as in step 8.

10. Send `initialize` first. Ask the developer which protocol version the client
    supports, send it as `params.protocolVersion`, and use the version the answer
    gives. Then send the `notifications/initialized` notification with no `id`.

11. Send `tools/list` to get the tools. Each tool has this shape:

    ```json
    {
      "name": "supplies__price_of",
      "description": "Reads data from the supplies hub.",
      "inputSchema": { "type": "object", "properties": { "item": {} } },
      "annotations": { "readOnlyHint": true }
    }
    ```

    `name` is `<served name>__<method>`, split at the first two underscores in a
    row. `inputSchema.properties` names each value the method takes and gives no
    type for any of them. A method that writes has `readOnlyHint: false` and the
    description `Changes data in the <served name> hub.` The list depends on who
    is signed in and in which account, so list again after either changes.

12. Ask the developer whether the client must confirm with the person before it
    calls a tool whose `readOnlyHint` is false. If it must, add that confirmation
    before step 13.

13. Send `tools/call` with the tool's name and its values:

    ```json
    {
      "jsonrpc": "2.0",
      "id": 2,
      "method": "tools/call",
      "params": { "name": "supplies__price_of", "arguments": { "item": "soap" } }
    }
    ```

    Send only the values named in that tool's `inputSchema.properties`. A
    successful call answers:

    ```json
    { "content": [ { "type": "text", "text": "\"soap costs 3\"" } ], "isError": false }
    ```

    `text` is the method's return value encoded as JSON, so parse it as JSON to
    get the value back.

14. Handle a tool error. These come back as a normal result with `isError: true`
    and the reason as the text:

    - The hub refused the call.
    - A value the method requires is missing.
    - A value the method is not listed with was sent, such as
      `price_of does not take colour`.
    - A record the call names does not exist, such as `No item has the id 9`.

    Show the reason to the person or the model making the call. Do not retry it
    unchanged.

15. Handle a JSON-RPC error. These come back as `error: { code, message }` with
    status 200, and with the request's `id` except for -32700 and -32600, whose
    `id` is null:

    | Code | Message | When |
    |---|---|---|
    | -32700 | `Parse error` | The body is not valid JSON. |
    | -32600 | `Invalid Request` | The body is not one JSON-RPC 2.0 request. |
    | -32601 | `Method not found: <method>` | The MCP method is not one of the four above. |
    | -32602 | `Unknown tool: <name>` | The tool does not exist, names a hub the host does not serve, or is one the caller may not call. |
    | -32603 | `Internal error` | A hub method raised an unexpected error. |

    -32602 reads the same in all three cases, so do not tell the person a tool
    does not exist when it may only be one they cannot call. -32603 never carries
    the error's own message, so find the cause in the host app's error reporting.

16. To read the apps a person has connected from the host's own code, call
    `HubKernel::Mcp::Connection.of` with the person record the host's sign-in
    gives. It answers a relation, so chain `includes`, `order` or `where` onto
    it:

    ```ruby
    HubKernel::Mcp::Connection.of(person).includes(:client).order(:created_at).each do |connection|
      connection.client.name   # the name the app registered with
      connection.created_at    # when the person approved it
      connection.last_used_at  # when its access token last signed a request in, or nil if never
    end
    ```

    There is one connection per approval, so an app approved twice is listed
    twice. A refresh keeps the same connection and its `created_at`. A
    connection stays listed after its tokens expire, until the person
    disconnects it. `last_used_at` is set each time the host's sign-in accepts
    the connection's access token. Ask the developer whether a list they build
    should show expired connections. To show the list on a settings page with
    Disconnect buttons, use the settings section `hub_kernel-mcp-install` covers
    instead of building one.

17. In a test of the host app, send requests the same way: a JSON POST to the
    endpoint's path, signed in as the host's tests sign in, plain GETs and POSTs
    to the discovery and registration addresses, the approval page's GET and
    POST signed in as the host's browser tests sign in, with the same query
    values as step 6 and `decision` set to `approve` or `deny` on the POST, a
    form POST to the token address with the code the approval sent back, and a
    form POST to the token address with the refresh token that trade gave:

    ```ruby
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, as: :json
    get "/.well-known/oauth-protected-resource/mcp"
    post "/mcp/register", params: { client_name: "Claude", redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ] }, as: :json
    get "/mcp/authorize", params: approval
    post "/mcp/authorize", params: approval.merge(decision: "approve")
    post "/mcp/token", params: { grant_type: "authorization_code", code: code, code_verifier: verifier, redirect_uri: approval[:redirect_uri], client_id: approval[:client_id] }
    post "/mcp/token", params: { grant_type: "refresh_token", refresh_token: refresh_token, client_id: approval[:client_id] }
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, as: :json, headers: { "Authorization" => "Bearer #{access_token}" }
    ```

    `approval` holds `response_type`, `client_id`, `redirect_uri`, `state`,
    `code_challenge` and `code_challenge_method` for a client registered in the
    test. `code` is read from the `code` query value of the approval POST's
    redirect, and `access_token` and `refresh_token` from a token POST's JSON
    answer.

## Conventions

- One request per POST to the endpoint, always with `"jsonrpc": "2.0"`, and an
  `id` on every request that needs an answer.
- Build tool names from `tools/list`, never by hand, since the list is what the
  signed-in person may call.
- Build sign-in addresses from the `WWW-Authenticate` header and the two
  discovery documents, never by hand.
- Send the approval page a fresh `state` and PKCE challenge on every attempt,
  check the `state` that comes back, and trade the code with that attempt's
  verifier and `redirect_uri`.
- Treat `isError: true` as an answer about the call, and a JSON-RPC `error` as an
  answer about the request.
- Registration needs no sign-in and holds no secret, so a `client_id` alone is
  never proof of who is calling.
- An access token lasts one hour. Refresh it with the latest refresh token and
  store both new tokens, since every refresh retires the pair it replaced.
- Send a person back to the approval page only after a refresh is refused with
  `invalid_grant`.
- The endpoint offers no sessions and no server-sent events, so do not open a GET
  stream or send a session header.
- Out of scope: installing the endpoint, mounting the discovery documents,
  installing the client, authorization code and connection migrations, choosing
  the endpoint's controller, sign-in, and served hubs, having the host's sign-in
  accept an access token, naming the approval page's controller, sign-in, person
  and layout, running the boot check, and registering the connections settings
  section and its Disconnect action, which belong to
  `hub_kernel-mcp-install`, and setting which methods a hub exposes, who may
  call them and their account scope, which belong to hub_kernel-interface.
