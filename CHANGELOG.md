# Changelog

## [Unreleased]

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
