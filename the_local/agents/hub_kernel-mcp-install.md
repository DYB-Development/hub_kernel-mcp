---
name: hub_kernel-mcp-install
description: Use to hook hub_kernel-mcp into a project — adding the gem, naming the controller the endpoint inherits from and the person and account methods on it, running the boot check after the served list is set, mounting the engine, and, for sign-in from a connector screen, installing the client migration and mounting the discovery documents.
tools: Bash, Read, Edit
scope: hub MCP tools — serving the methods every hub a host serves, from hub_kernel-interface's one served list, as MCP tools at one JSON-RPC endpoint in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope, with a boot check for hubs that cannot be served as tools, and the OAuth discovery documents, 401 challenge and client registration that let a client such as Claude's connector screen find the endpoint's sign-in and register by itself
---

This local follows these steps exactly and invents none. Where a step names a
decision, it asks the developer and does not pick.

## What hub_kernel-mcp is

A Rails engine that serves every method the host's hubs expose as MCP tools at
one JSON-RPC endpoint. Hook it in when the host already serves hubs through
hub_kernel-interface and wants an MCP client to call them on a signed-in
person's behalf.

## Interface

- `gem "hub_kernel-mcp"` — adds the gem to the host's `Gemfile`. It requires
  Rails 8.1.3 or later and Ruby 3.2 or later, and brings in
  `hub_kernel-interface` `~> 0.6`.
- `mount HubKernel::Mcp::Engine` — mounts the endpoint in the host's
  `config/routes.rb` at the path given. The path answers POST with JSON-RPC and
  answers GET with status 405. A client registers at `<path>/register`, and
  every 401 the endpoint answers carries a `WWW-Authenticate` header pointing at
  the discovery documents.
- `mount HubKernel::Mcp::Discovery` — mounts the two OAuth discovery documents
  in the host's `config/routes.rb`. It must be mounted at `"/.well-known"`,
  since the endpoint's 401 header names that path.
- `bin/rails hub_kernel_mcp:install:migrations` — copies the gem's migration
  into the host's `db/migrate`. It creates the `hub_kernel_mcp_clients` table,
  which holds each client that registers.
- `HubKernel::Mcp.base_controller=` — the name, as a String, of the host
  controller the endpoint inherits from. Its before-actions, including sign-in,
  run before any hub is asked. Defaults to `"ActionController::API"`, which has
  no sign-in.
- `HubKernel::Mcp.person_method=` — the name, as a Symbol, of the method on the
  base controller that returns the person a request is made for. No default.
- `HubKernel::Mcp.account_method=` — the name, as a Symbol, of the method on the
  base controller that returns the account a request is scoped to. No default.
- `HubKernel::Mcp.check!` — the boot check. Raises
  `HubKernel::Mcp::UnservableHubError` when any served hub cannot be served as
  tools, and returns nothing otherwise.
- `HubKernel::Mcp::UnservableHubError` — the error `check!` raises. Its message
  names every problem found, one per line. It is the same class as
  `HubKernel::Interface::UnservableHubError`, so rescuing either catches it.

## How to use it

1. Add the gem to the host's `Gemfile` and install it:

   ```ruby
   gem "hub_kernel-mcp"
   ```

   ```
   bundle install
   ```

2. Ask the developer which host controller the endpoint should inherit from.
   It must already sign the caller in and refuse a caller who is not signed in,
   in a before-action, since the endpoint adds no sign-in of its own. It must
   also accept a JSON POST with no CSRF token: an `ActionController::API`
   subclass does, and an `ActionController::Base` subclass with forgery
   protection refuses every request unless that protection is skipped for this
   endpoint. Ask whether to use an existing controller or add a new one, and do
   not choose the sign-in method yourself.

3. Ask the developer which method on that controller returns the person a
   request is made for, and which returns the account it is scoped to. Both are
   called on the controller with no arguments, may be private, and must exist
   on the base controller or a class it inherits from. If either is missing,
   ask what it should return before adding it.

4. Create `config/initializers/hub_kernel_mcp.rb` with the three answers:

   ```ruby
   HubKernel::Mcp.base_controller = "Api::HubBaseController"
   HubKernel::Mcp.person_method = :current_person
   HubKernel::Mcp.account_method = :current_account
   ```

   Set these in an initializer, not in `to_prepare`, so they are set before the
   endpoint's controller loads. The controller name is a String. Leaving
   `person_method` or `account_method` unset makes every `tools/list` and
   `tools/call` request answer with JSON-RPC error -32603, `Internal error`.

5. Find where the host sets its served list, `HubKernel::Interface.hubs = [...]`,
   inside `Rails.application.config.to_prepare`. Add `HubKernel::Mcp.check!` on
   the line after it, in the same block:

   ```ruby
   Rails.application.config.to_prepare do
     HubKernel::Interface.hubs = [ Supplies, { "money" => Billing::Ledger } ]
     HubKernel::Mcp.check!
   end
   ```

   If the block already calls `HubKernel::Interface.check!`, keep or remove it
   as the developer prefers, since `HubKernel::Mcp.check!` reports every problem
   that check finds as well. If the host sets no served list yet, stop and tell
   the developer that the hubs to serve are chosen in hub_kernel-interface
   first, and do not invent the list.

6. Ask the developer what path to mount the endpoint at, then add the mount to
   `config/routes.rb`:

   ```ruby
   mount HubKernel::Mcp::Engine => "/mcp"
   ```

7. Ask the developer whether a client such as Claude's connector screen should
   find the endpoint's sign-in and register by itself, so a person only pastes
   the endpoint's address. If not, stop here and skip steps 8 to 10.

8. Copy the gem's migration into the host and run it:

   ```
   bin/rails hub_kernel_mcp:install:migrations db:migrate
   ```

   This adds a migration to the host's `db/migrate` and the
   `hub_kernel_mcp_clients` table to `db/schema.rb`. Commit both.

9. Add the discovery mount to `config/routes.rb`, at the site root beside the
   endpoint's mount, at exactly `"/.well-known"`:

   ```ruby
   mount HubKernel::Mcp::Engine => "/mcp"
   mount HubKernel::Mcp::Discovery => "/.well-known"
   ```

   If the host already routes anything under `/.well-known`, show the developer
   those routes and ask how to combine them before adding the mount.

10. Check how the base controller from step 2 refuses a caller who is not
    signed in. A connector screen finds the sign-in only from a response with
    status 401. If the controller redirects to a sign-in page or answers any
    other status, tell the developer, and ask whether to change it to answer
    401 for this endpoint.

## Conventions

- After installing, boot the app or run `bin/rails runner "HubKernel::Mcp.check!"`.
  An `UnservableHubError` there lists every problem to fix, one per line: a
  problem hub_kernel-interface's own check finds, a served name holding two
  underscores in a row, a tool name holding a character other than a letter, a
  digit, an underscore or a hyphen, or a tool name longer than 64 characters.
  A tool name is `<served name>__<method>`.
- Fix a check failure by changing the served name or the hub method in the host,
  never by removing the check. Inside `to_prepare` the check runs again after
  every code reload.
- Run the check again whenever the served list changes or a hub gains a method.
- A change to `config/initializers/hub_kernel_mcp.rb` takes effect only after
  the app restarts.
- With discovery installed, check it with
  `curl -i -X POST <host>/mcp` while signed out: the response should be 401 with
  a `WWW-Authenticate` header naming
  `<host>/.well-known/oauth-protected-resource/mcp`, and a GET to that address
  should name the endpoint.
- Run `bin/rails hub_kernel_mcp:install:migrations` again after upgrading the
  gem, then `db:migrate`. It copies only migrations the host does not have yet.
- The sign-in document names approval and token addresses under the endpoint's
  path, `<path>/authorize` and `<path>/token`. This version of the gem does not
  answer either, so a connector screen can register but cannot finish signing
  in through the gem alone. Tell the developer this when they choose step 7.
- Out of scope: choosing which hubs are served and setting permissions and
  account scope, which belong to hub_kernel-interface, and changing what the
  endpoint or the discovery documents answer, which belongs to
  `hub_kernel-mcp-develop`.
