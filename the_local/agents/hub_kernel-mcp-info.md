---
name: hub_kernel-mcp-info
description: Use to learn what hub_kernel-mcp offers — serving a host's hubs as MCP tools, how tools are named and scoped, how a client such as Claude's connector screen finds the endpoint's sign-in, registers itself, is approved by a person through the browser, trades its code for an access token and a refresh token and later trades the refresh token for a new pair, how each sign-in step refuses a bad request or an unexpected error, how many clients one address may register in an hour, how the host's sign-in finds the person a token acts for, how a person sees and disconnects the apps connected as them, how expired sign-in records are removed, and the vocabulary the install and develop locals assume.
tools: Read
scope: hub MCP tools — serving the methods every hub a host serves, from hub_kernel-interface's one served list, as MCP tools at one JSON-RPC endpoint in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope, with a boot check for hubs that cannot be served as tools, the OAuth discovery documents, 401 challenge and client registration that let a client such as Claude's connector screen find the endpoint's sign-in and register by itself, with each client recording the address it registered from and a configurable limit on how many clients one address may register per hour past which registration is refused, and the approval page where a person signed in to the host through the browser approves that client and is issued an authorization code, the token exchange that trades that code with its PKCE verifier for an access token lasting an hour and a refresh token, the refresh exchange that trades a refresh token for a new access token and a new refresh token and retires the one posted, and the lookup a host's sign-in calls to get the person a bearer token acts for, which records when the connection was last used, and the settings section a host registers with settings_hub that lists a person's connections with the app's name, when it connected and when it was last used, and disconnects one that is the person's own, and the prune task a host schedules with its own job runner that removes expired authorization codes, connections whose access and refresh tokens have both expired, and clients over a day old with no connection
---

This local explains hub_kernel-mcp and makes no changes.

## What hub_kernel-mcp is

hub_kernel-mcp lets an MCP client, such as an AI assistant, call the methods a
Rails host app's hubs expose. It reads the host's one served list from
hub_kernel-interface, the same list every interface gem reads, and offers each
method the caller may call as an MCP tool at a single JSON-RPC endpoint inside
the host app.

Reach for it when a host already serves hubs through hub_kernel-interface and
wants an assistant to read or change that data on a person's behalf. Every call
passes through the host's own sign-in first, then hub_kernel-interface's
permission check and account scope, so a tool can do nothing the signed-in
person could not already do. A boot check refuses to start a host whose served
hubs cannot be turned into valid tool names, or whose browser settings for the
approval page are not all set.

The gem also lets a client set itself up from the endpoint's address alone. A
refused request tells the client where the endpoint is described, two discovery
documents name the endpoint's sign-in and its registration address, and the
client registers itself there with its name and redirect addresses. The client
then sends the person to an approval page in the host, where they sign in
through the host's usual browser sign-in and approve or deny the client. An
approval gives the client an authorization code, which it trades at the token
address for an access token lasting an hour and a refresh token. When the
access token runs out, the client trades the refresh token at the same address
for a new pair, so the person does not approve the client again. The client
sends the access token on every request, and the host's sign-in asks the gem
which person the token acts for. A person using Claude's connector screen only
pastes the endpoint's address.

A person can see which apps are connected as them, and cut one off. The gem
ships a section for a host's settings page, registered through settings_hub,
that lists each of the person's connections with the app's name, when it
connected and when it was last used, and a Disconnect button for each. A
disconnected app's tokens stop working at once.

Registration needs no sign-in, so the gem keeps it and the records it leaves
bounded. One address may register only a set number of clients in an hour, ten
unless the host changes it. The gem also ships a prune task that removes
authorization codes, connections and clients that can no longer be used. The
gem does not run the task itself, so the host schedules it with its own job
runner.

## Interface

This local declares no entry points of its own.

- Adding the gem to a host, mounting the endpoint and the discovery documents,
  installing the client, authorization code and connection tables, configuring
  which controllers, person, account and sign-in methods and layout it uses,
  setting the registration limit, running the boot check, calling the token
  lookup from the host's sign-in, registering the connections section and its
  disconnect action with settings_hub, and scheduling the prune task are owned
  by the install local, `hub_kernel-mcp-install`.
- The endpoint itself, the MCP requests it answers, the discovery documents,
  the challenge on a refused request, client registration, the approval page,
  the token exchange, the refresh exchange, how each of them refuses, and the
  query for a person's connections are owned by the develop local,
  `hub_kernel-mcp-develop`.

## How to use it

- To put hub_kernel-mcp into a Rails app, to let a connector screen sign in to
  it, to point the approval page at the host's browser sign-in and layout, to
  make the host's sign-in accept the access tokens this gem issues, to add the
  connected apps section to the host's settings page, to raise or lower how
  many clients one address may register in an hour, to schedule the removal of
  expired sign-in records, or to fix a host whose boot check fails, use
  `hub_kernel-mcp-install`.
- To change what the endpoint answers, add support for another MCP request,
  change how tools are listed, called or refused, change what the discovery
  documents and registration say, change what the approval page checks and
  shows, change when a code or a refresh token is traded for new tokens, change
  how long either token lasts, change how a sign-in step refuses, or change
  which connections count as a person's own, use `hub_kernel-mcp-develop`.
- To decide which hubs are served at all, or to change permissions and account
  scope, work in hub_kernel-interface, which owns the served list and those
  checks.

## Conventions

- **Host** — the Rails app that mounts the endpoint and serves the hubs.
- **Hub** — a hub_kernel object whose exposed methods are the units a caller may
  call. hub_kernel-mcp defines no hubs.
- **Served list and served name** — the host's one list of hubs in
  hub_kernel-interface, where each hub is served under a name. A served name may
  not hold two underscores in a row.
- **Tool** — one exposed hub method, named `<served name>__<method>`, using only
  letters, digits, underscores and hyphens, and at most 64 characters long. Its
  input schema names the values the method takes.
- **Reads and writes** — a tool for a method that writes is marked as not
  read-only and described as changing data, so a client can ask before calling
  it.
- **Person and account** — who a request is made for and which account it is
  scoped to, both supplied by methods on the host's own controller.
- **Tool error and JSON-RPC error** — a hub's refusal, a missing or unlisted
  value, or a record that does not exist comes back as a tool error carrying the
  reason. A tool the caller may not call, or one that does not exist, comes back
  as the same JSON-RPC error, `Unknown tool`, so a caller cannot tell the two
  apart. An unexpected error is reported to the host's error reporting and its
  message is never sent to the client.
- **Challenge** — the header added to every 401 the endpoint returns, pointing
  the client at the document that describes the endpoint.
- **Discovery documents** — two OAuth documents served at the site root. The
  resource document names the endpoint's address and its sign-in, which is the
  site root. The sign-in document names the registration, approval and token
  addresses under the endpoint's address, names the authorization code and
  refresh grants as the ones it accepts, and requires PKCE with SHA-256 and no
  client secret.
- **Client and registration** — a client is an app that registered itself by
  posting its name and redirect addresses, and is answered with a client id.
  Every redirect address must be HTTPS, or plain HTTP on the client's own
  machine, and a registration with none or with any other address is refused
  with the reason. A registration body that is not valid JSON is refused as
  invalid client metadata.
- **Registration limit** — each client records the address it registered
  from. Once one address has registered as many clients in the last hour as the
  limit allows, ten by default, its next registration is refused with status
  429 and the reason, and no client is created.
- **Browser side** — the approval page runs on a host controller meant for
  people in a browser, separate from the endpoint's controller. The host names
  that controller, the method that makes a person sign in, the method that
  returns the signed-in person, and the layout the page renders in.
- **Approval page** — shows which client wants to connect as the signed-in
  person, with an approve and a deny button. A request missing its client id or
  redirect address, naming a client that is not registered, or naming a
  redirect address the client did not register gets an error page saying which,
  and nothing is sent to any address. A request without a SHA-256 PKCE
  challenge is sent back to the client as an invalid request. A denial is sent
  back to the client as access denied.
- **Authorization code** — what an approval sends back to the client's redirect
  address, along with the client's state. It is tied to the person, the client,
  the redirect address and the PKCE challenge, lasts ten minutes, and only a
  digest of it is stored.
- **Token exchange** — the client posts its client id, its code, its redirect
  address and its PKCE verifier to the token address, with no sign-in. A code
  that is unknown, expired, already traded, issued to another client, sent with
  a different redirect address or with a verifier that does not match is refused
  as an invalid grant. A code is traded once. A code posted a second time also
  stops the access and refresh tokens already issued from it. A grant other than
  the authorization code and refresh grants is refused as unsupported, and a
  body that cannot be read is refused as an invalid request.
- **Access token, refresh token and connection** — what a traded code is
  answered with: a bearer access token that lasts an hour and a refresh token
  that lasts ninety days. The pair is stored as a connection tying the person
  and the client to a digest of each token, so neither token itself is stored.
- **Refresh exchange** — the client posts its client id and its refresh token to
  the token address, asking for the refresh grant, with no sign-in. It is
  answered with a new access token and a new refresh token on the same
  connection, and the new refresh token lasts another ninety days. The refresh
  token posted and the access token it was issued with both stop working. A
  refresh token that is unknown, already used, issued to another client, or
  unused for ninety days is refused as an invalid grant, and of two refreshes
  posting the same token at once only one succeeds.
- **Unexpected error at a sign-in step** — an error nobody planned for at the
  registration address, the token address or a discovery document is answered
  with status 500 and a server error. On the approval page it shows the error
  page instead. Either way its message is never sent to the client or shown to
  the person, and it is reported to the host's error reporting.
- **Token lookup** — what the host's sign-in calls with the bearer token from a
  request. It gives the person the access token acts for while the token is
  unexpired, and nothing for an expired, replaced or unknown token. Each lookup
  that finds a person records the time on the connection as when it was last
  used. The account a call is made in still comes from the host's account
  method.
- **Connections section** — the part of a host's settings page that lists the
  signed-in person's connections, oldest first, each with the app's name, when
  it connected, and when it was last used or that it was never used. It is
  given the person and the address its Disconnect buttons post to.
- **Disconnect** — the action a Disconnect button runs. It deletes the
  connection, so both of its tokens stop working at once. A connection that is
  not the person's own is left alone and the person is told it is not one of
  theirs.
- **Prune** — the task that removes sign-in records nothing can use any more:
  authorization codes past their ten minutes, connections whose access token
  and refresh token have both expired, and clients registered over a day ago
  that hold no connection and no authorization code. A connection with either
  token still working is never removed. The gem never runs it on its own.
