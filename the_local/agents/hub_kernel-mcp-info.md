---
name: hub_kernel-mcp-info
description: Use to learn what hub_kernel-mcp offers — serving a host's hubs as MCP tools, how tools are named and scoped, how a client such as Claude's connector screen finds the endpoint's sign-in, registers itself, is approved by a person through the browser and trades its code for an access token, how the host's sign-in finds the person a token acts for, and the vocabulary the install and develop locals assume.
tools: Read
scope: hub MCP tools — serving the methods every hub a host serves, from hub_kernel-interface's one served list, as MCP tools at one JSON-RPC endpoint in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope, with a boot check for hubs that cannot be served as tools, the OAuth discovery documents, 401 challenge and client registration that let a client such as Claude's connector screen find the endpoint's sign-in and register by itself, and the approval page where a person signed in to the host through the browser approves that client and is issued an authorization code, the token exchange that trades that code with its PKCE verifier for an access token lasting an hour, and the lookup a host's sign-in calls to get the person a bearer token acts for
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
address for an access token lasting an hour. The client sends that token on
every request, and the host's sign-in asks the gem which person the token acts
for. A person using Claude's connector screen only pastes the endpoint's
address.

## Interface

This local declares no entry points of its own.

- Adding the gem to a host, mounting the endpoint and the discovery documents,
  installing the client, authorization code and connection tables, configuring
  which controllers, person, account and sign-in methods and layout it uses,
  running the boot check, and calling the token lookup from the host's sign-in
  are owned by the install local, `hub_kernel-mcp-install`.
- The endpoint itself, the MCP requests it answers, the discovery documents,
  the challenge on a refused request, client registration, the approval page and
  the token exchange are owned by the develop local, `hub_kernel-mcp-develop`.

## How to use it

- To put hub_kernel-mcp into a Rails app, to let a connector screen sign in to
  it, to point the approval page at the host's browser sign-in and layout, to
  make the host's sign-in accept the access tokens this gem issues, or to fix a
  host whose boot check fails, use `hub_kernel-mcp-install`.
- To change what the endpoint answers, add support for another MCP request,
  change how tools are listed, called or refused, change what the discovery
  documents and registration say, change what the approval page checks and
  shows, or change when a code is traded for a token and how long the token
  lasts, use `hub_kernel-mcp-develop`.
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
  addresses under the endpoint's address, and requires PKCE with SHA-256 and no
  client secret.
- **Client and registration** — a client is an app that registered itself by
  posting its name and redirect addresses, and is answered with a client id.
  Every redirect address must be HTTPS, or plain HTTP on the client's own
  machine, and a registration with none or with any other address is refused
  with the reason.
- **Browser side** — the approval page runs on a host controller meant for
  people in a browser, separate from the endpoint's controller. The host names
  that controller, the method that makes a person sign in, the method that
  returns the signed-in person, and the layout the page renders in.
- **Approval page** — shows which client wants to connect as the signed-in
  person, with an approve and a deny button. A redirect address the client did
  not register gets an error page and nothing is sent to that address. A request
  without a SHA-256 PKCE challenge is sent back to the client as an invalid
  request. A denial is sent back to the client as access denied.
- **Authorization code** — what an approval sends back to the client's redirect
  address, along with the client's state. It is tied to the person, the client,
  the redirect address and the PKCE challenge, lasts ten minutes, and only a
  digest of it is stored.
- **Token exchange** — the client posts its code, its redirect address and its
  PKCE verifier to the token address, with no sign-in. A code that is unknown,
  expired, already traded, sent with a different redirect address or with a
  verifier that does not match is refused as an invalid grant. A code is traded
  once and then cannot be traded again.
- **Access token and connection** — what a traded code is answered with: a
  bearer token that lasts an hour, with no refresh token. Each one is stored as
  a connection tying the person and the client to a digest of the token, so the
  token itself is never stored.
- **Token lookup** — what the host's sign-in calls with the bearer token from a
  request. It gives the person the token acts for while the token is unexpired,
  and nothing for an expired or unknown token. The account a call is made in
  still comes from the host's account method.
