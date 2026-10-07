# Changelog

## [Unreleased]

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
