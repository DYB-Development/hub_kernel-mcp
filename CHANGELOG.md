# Changelog

## [Unreleased]

## [0.8.1] - 2026-10-08

### Fixed
- In a host that uses Turbo, Approve and Deny on the approval page take the person back to the client's redirect address, where before the page stayed put and the client never heard the answer.

## [0.8.0] - 2026-10-08

### Added
- A client such as Claude's connector screen can find the endpoint's sign-in by itself: every 401 names where the endpoint is described, and `HubKernel::Mcp::Discovery`, mounted at `/.well-known`, serves the endpoint's description and the sign-in's.
- A client registers itself at `/register` with its name and redirect addresses, which must be HTTPS or on the client's own machine.
- An approval page at `/authorize` runs inside the host's controller and layout, signs a person in through the host's sign-in, and sends them back to the client with a code or `access_denied`.
- `HubKernel::Mcp.browser_controller`, `sign_in_method`, `browser_person_method` and `browser_layout` name what the approval page runs in, and `HubKernel::Mcp.check!` names each one a host has not set.
- A client trades a code and its PKCE verifier at `/token` for an access token lasting an hour and a refresh token, and trades a refresh token for a new pair.
- `HubKernel::Mcp::Connection.person_for` gives a host's sign-in the person an access token acts for.
- The `hub_kernel/mcp/connections` partial and the `HubKernel::Mcp::Disconnect` action give a host's settings page a list of a person's connected apps and a way to disconnect one.
- `HubKernel::Mcp.registration_limit` limits how many clients one address may register an hour.
- `bin/rails hub_kernel_mcp:prune` removes expired codes, connections that can no longer be used, and clients over a day old with no connection.
- The gem ships migrations, installed with `bin/rails hub_kernel_mcp:install:migrations`.

### Changed
- A host must set the four approval page settings, or `HubKernel::Mcp.check!` raises at boot.

## [0.7.0] - 2026-10-07

### Added
- hub_kernel-mcp is a the_local provider: installing it gives an app its info, install and develop agents.

## [0.6.0] - 2026-10-07

### Added
- A `ping` is answered with an empty result.
- A body that is not valid JSON, a body that is not one JSON-RPC request, and an MCP method the endpoint does not support are each answered with their JSON-RPC error.
- An unexpected error inside a hub method is answered as an internal error without its message, and reported to the host app's error reporting.
- A GET to the endpoint's address is answered with status 405.

## [0.5.0] - 2026-10-07

### Changed
- A permitted call sending a value its method is not listed with comes back as a tool error naming the value, where the value used to be dropped.
- A call naming a record that does not exist comes back as a tool error naming the kind of record and the id.

## [0.4.0] - 2026-10-07

### Added
- `HubKernel::Mcp.check!`, which raises `HubKernel::Mcp::UnservableHubError` naming each problem hub_kernel-interface's check finds, a served name holding two underscores in a row, and a tool name MCP does not allow.

### Changed
- hub_kernel-mcp requires hub_kernel-interface 0.6.

## [0.3.0] - 2026-10-06

### Added
- Each listed tool says whether it only reads or changes data, as a `readOnlyHint` annotation and in a description naming its hub.

## [0.2.0] - 2026-10-06

### Added
- `tools/call`, which runs the hub method a tool names and returns its answer, or the hub's refusal as a tool error.

## [0.1.0] - 2026-10-06

### Added
- An MCP endpoint at the address the host mounts the engine at, behind the host's own sign-in.
- `initialize`, which answers the server's name, version, tools capability and protocol version.
- `tools/list`, which lists one tool for each method the caller may call across every hub the host serves.
