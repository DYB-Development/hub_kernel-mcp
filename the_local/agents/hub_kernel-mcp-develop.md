---
name: hub_kernel-mcp-develop
description: Use PROACTIVELY for calling a host's hub methods over MCP — connecting an MCP client to the endpoint, sending initialize and ping, listing the tools a signed-in person may call with tools/list, calling one with tools/call, and handling its tool errors and JSON-RPC errors — MUST BE USED instead of hand-rolling a JSON API or MCP server for the host's hubs.
tools: Read, Write, Edit, Grep
scope: hub MCP tools — serving the methods every hub a host serves, from hub_kernel-interface's one served list, as MCP tools at one JSON-RPC endpoint in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope, with a boot check for hubs that cannot be served as tools
---

This local writes the code or configuration that talks to a host's hub_kernel-mcp
endpoint, following these steps exactly. Where a step names a decision, it asks
the developer and does not pick.

## What hub_kernel-mcp is

A JSON-RPC endpoint in a host Rails app that offers every method the host's hubs
expose as an MCP tool, for the person and account the host's sign-in gives.
Fire this local when code or a client needs to list or call those tools, or when
a test needs to send requests to the endpoint.

## Interface

- `POST /` — the endpoint, at the path the host serves it under. It takes one
  JSON-RPC 2.0 request per POST as a JSON body. A GET to the same path is
  answered with status 405 and `Allow: POST`.
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

## How to use it

1. Find the path the host serves the endpoint at in its `config/routes.rb`. If
   it is not there, stop and tell the developer the endpoint is not installed
   yet.

2. Ask the developer how the client signs in. Every request runs the host's own
   sign-in first, so the client must send whatever that sign-in expects, such as
   a session cookie or a token header. A request the sign-in refuses gets the
   host's refusal, for example status 401, and no hub is asked. Do not choose the
   credential yourself.

3. Send every request as a POST with a JSON body holding exactly one request:

   ```json
   { "jsonrpc": "2.0", "id": 1, "method": "tools/list" }
   ```

   `jsonrpc` must be `"2.0"` and `method` must be a string. A batch, a JSON array
   of requests, is refused with -32600. A request with no `id` is a
   notification: it is answered with status 202 and no body, and nothing is run.

4. Send `initialize` first. Ask the developer which protocol version the client
   supports, send it as `params.protocolVersion`, and use the version the answer
   gives. Then send the `notifications/initialized` notification with no `id`.

5. Send `tools/list` to get the tools. Each tool has this shape:

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

6. Ask the developer whether the client must confirm with the person before it
   calls a tool whose `readOnlyHint` is false. If it must, add that confirmation
   before step 7.

7. Send `tools/call` with the tool's name and its values:

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

8. Handle a tool error. These come back as a normal result with `isError: true`
   and the reason as the text:

   - The hub refused the call.
   - A value the method requires is missing.
   - A value the method is not listed with was sent, such as
     `price_of does not take colour`.
   - A record the call names does not exist, such as `No item has the id 9`.

   Show the reason to the person or the model making the call. Do not retry it
   unchanged.

9. Handle a JSON-RPC error. These come back as `error: { code, message }` with
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

10. In a test of the host app, send requests the same way, as a JSON POST to the
    endpoint's path, signed in as the host's tests sign in:

    ```ruby
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }, as: :json
    ```

## Conventions

- One request per POST, always with `"jsonrpc": "2.0"`, and an `id` on every
  request that needs an answer.
- Build tool names from `tools/list`, never by hand, since the list is what the
  signed-in person may call.
- Treat `isError: true` as an answer about the call, and a JSON-RPC `error` as an
  answer about the request.
- The endpoint offers no sessions and no server-sent events, so do not open a GET
  stream or send a session header.
- Out of scope: installing the endpoint, choosing its controller, sign-in, and
  served hubs, and running the boot check, which belong to
  `hub_kernel-mcp-install`, and setting which methods a hub exposes, who may
  call them and their account scope, which belong to hub_kernel-interface.
