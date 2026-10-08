---
name: hub_kernel-mcp-install
description: Use to hook hub_kernel-mcp into a project — adding the gem, naming the controller the endpoint inherits from and the person and account methods on it, naming the browser controller, sign-in method, person method and layout the approval page runs with, running the boot check after the served list is set, mounting the engine, and, for sign-in from a connector screen, installing the migrations, mounting the discovery documents, and having the host's sign-in look up the person an access token acts for.
tools: Bash, Read, Edit
scope: hub MCP tools — serving the methods every hub a host serves, from hub_kernel-interface's one served list, as MCP tools at one JSON-RPC endpoint in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope, with a boot check for hubs that cannot be served as tools, the OAuth discovery documents, 401 challenge and client registration that let a client such as Claude's connector screen find the endpoint's sign-in and register by itself, and the approval page where a person signed in to the host through the browser approves that client and is issued an authorization code, the token exchange that trades that code with its PKCE verifier for an access token lasting an hour and a refresh token, the refresh exchange that trades a refresh token for a new access token and a new refresh token and retires the one posted, and the lookup a host's sign-in calls to get the person a bearer token acts for
---

This local follows these steps exactly and invents none. Where a step names a
decision, it asks the developer and does not pick.

## What hub_kernel-mcp is

A Rails engine that serves every method the host's hubs expose as MCP tools at
one JSON-RPC endpoint, with a browser page where a signed-in person approves a
client such as Claude's connector screen. Hook it in when the host already
serves hubs through hub_kernel-interface and wants an MCP client to call them on
a signed-in person's behalf.

## Interface

- `gem "hub_kernel-mcp"` — adds the gem to the host's `Gemfile`. It requires
  Rails 8.1.3 or later and Ruby 3.2 or later, and brings in
  `hub_kernel-interface` `~> 0.6`.
- `mount HubKernel::Mcp::Engine` — mounts the endpoint in the host's
  `config/routes.rb` at the path given. The path answers POST with JSON-RPC and
  answers GET with status 405. A client registers at `<path>/register`, a person
  approves it at `<path>/authorize`, the client trades the approval's code for an
  access token and a refresh token at `<path>/token` and later trades the
  refresh token there for a new pair, and every 401 the endpoint answers carries a
  `WWW-Authenticate` header pointing at the discovery documents.
- `mount HubKernel::Mcp::Discovery` — mounts the two OAuth discovery documents
  in the host's `config/routes.rb`. It must be mounted at `"/.well-known"`,
  since the endpoint's 401 header names that path.
- `bin/rails hub_kernel_mcp:install:migrations` — copies the gem's four
  migrations into the host's `db/migrate`. They create the
  `hub_kernel_mcp_clients` table, which holds each client that registers, the
  `hub_kernel_mcp_authorization_codes` table, which holds each code the
  approval page issues, and the `hub_kernel_mcp_connections` table, which holds
  each access token issued for a code, and then add the refresh token's columns
  to `hub_kernel_mcp_connections`.
- `HubKernel::Mcp.base_controller=` — the name, as a String, of the host
  controller the endpoint inherits from. Its before-actions, including sign-in,
  run before any hub is asked. Defaults to `"ActionController::API"`, which has
  no sign-in.
- `HubKernel::Mcp.person_method=` — the name, as a Symbol, of the method on the
  base controller that returns the person a request is made for. No default.
- `HubKernel::Mcp.account_method=` — the name, as a Symbol, of the method on the
  base controller that returns the account a request is scoped to. No default.
- `HubKernel::Mcp.browser_controller=` — the name, as a String, of the host
  controller the approval page inherits from. It must render HTML views, so it
  is an `ActionController::Base` subclass. No default.
- `HubKernel::Mcp.sign_in_method=` — the name, as a Symbol, of the method on the
  browser controller that sends a person who is not signed in through the
  host's sign-in. The approval page calls it with no arguments before anything
  else. No default.
- `HubKernel::Mcp.browser_person_method=` — the name, as a Symbol, of the method
  on the browser controller that returns the signed-in person. That person must
  be a record with a global id, since the issued code keeps the person by it.
  No default.
- `HubKernel::Mcp.browser_layout=` — the name, as a String, of the host layout
  the approval page is shown in. No default.
- `HubKernel::Mcp.check!` — the boot check. Raises
  `HubKernel::Mcp::UnservableHubError` when any served hub cannot be served as
  tools, or when any of the four browser settings is not set, and returns
  nothing otherwise.
- `HubKernel::Mcp::UnservableHubError` — the error `check!` raises. Its message
  names every problem found, one per line. It is the same class as
  `HubKernel::Interface::UnservableHubError`, so rescuing either catches it.
- `HubKernel::Mcp::Connection.person_for` — takes the bearer token a client
  sends, as a String, and returns the person who approved the client the token
  was issued to. Returns `nil` for a token that is unknown, more than an hour
  old, or replaced by a refresh. The host's sign-in on the base controller
  calls it.

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

4. Ask the developer which host controller the approval page should inherit
   from. It is the controller the host's browser pages use, usually
   `ApplicationController`, and must be an `ActionController::Base` subclass.
   Then ask for three names on it:

   - the method that sends a person who is not signed in to the host's sign-in,
     such as Devise's `:authenticate_user!`;
   - the method that returns the signed-in person, such as `:current_user`;
   - the layout the page is shown in, such as `"application"`.

   All four are required, even when no connector screen will sign in: the boot
   check names each one left unset, and the approval page's controller cannot
   load without the browser controller. Do not choose any of them yourself.

5. Create `config/initializers/hub_kernel_mcp.rb` with the answers from steps 2
   to 4:

   ```ruby
   HubKernel::Mcp.base_controller = "Api::HubBaseController"
   HubKernel::Mcp.person_method = :current_person
   HubKernel::Mcp.account_method = :current_account

   HubKernel::Mcp.browser_controller = "ApplicationController"
   HubKernel::Mcp.sign_in_method = :authenticate_user!
   HubKernel::Mcp.browser_person_method = :current_user
   HubKernel::Mcp.browser_layout = "application"
   ```

   Set these in an initializer, not in `to_prepare`, so they are set before the
   gem's controllers load. Both controller names and the layout are Strings, and
   the three method names are Symbols. Leaving `person_method` or
   `account_method` unset makes every `tools/list` and `tools/call` request
   answer with JSON-RPC error -32603, `Internal error`.

6. Find where the host sets its served list, `HubKernel::Interface.hubs = [...]`,
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

7. Ask the developer what path to mount the endpoint at, then add the mount to
   `config/routes.rb`:

   ```ruby
   mount HubKernel::Mcp::Engine => "/mcp"
   ```

8. Ask the developer whether a client such as Claude's connector screen should
   find the endpoint's sign-in, register and be approved by a person, so a
   person only pastes the endpoint's address. If not, stop here and skip steps
   9 to 13.

9. Copy the gem's migrations into the host and run them:

   ```
   bin/rails hub_kernel_mcp:install:migrations db:migrate
   ```

   This adds four migrations to the host's `db/migrate` and the
   `hub_kernel_mcp_clients`, `hub_kernel_mcp_authorization_codes` and
   `hub_kernel_mcp_connections` tables to `db/schema.rb`. Commit all five files.

10. Add the discovery mount to `config/routes.rb`, at the site root beside the
    endpoint's mount, at exactly `"/.well-known"`:

    ```ruby
    mount HubKernel::Mcp::Engine => "/mcp"
    mount HubKernel::Mcp::Discovery => "/.well-known"
    ```

    If the host already routes anything under `/.well-known`, show the developer
    those routes and ask how to combine them before adding the mount.

11. Check how the base controller from step 2 refuses a caller who is not
    signed in. A connector screen finds the sign-in only from a response with
    status 401. If the controller redirects to a sign-in page or answers any
    other status, tell the developer, and ask whether to change it to answer
    401 for this endpoint.

12. Check whether the base controller's sign-in accepts the access token a
    connector screen sends on every request, as `Authorization: Bearer <token>`.
    The gem issues the token but does not sign anyone in with it, so the base
    controller's person method must look the token up:

    ```ruby
    class Api::McpBaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action { head :unauthorized unless current_person }

      private

      def current_person = authenticate_with_http_token { |token| HubKernel::Mcp::Connection.person_for(token) }
    end
    ```

    If the base controller already signs callers in another way, such as with
    an API key, ask the developer whether a bearer token from
    `HubKernel::Mcp::Connection.person_for` should be accepted in addition to
    it or in its place, and do not choose. A `nil` from `person_for` must end in
    a 401, as in step 11. Then check that the account method from step 3 returns
    an account for a person signed in this way, since every call is made in that
    account. If it reads the account from something a token request does not
    carry, such as a session or a subdomain, tell the developer and ask what it
    should return.

13. Check the layout from step 4. The approval page runs inside the gem's
    engine, so a route helper the layout calls for one of the host's own routes,
    such as `root_path`, must be written `main_app.root_path`. If the layout
    calls any host route helper without `main_app.`, show the developer each one
    and ask whether to prefix them or to name a different layout.

## Conventions

- After installing, boot the app or run `bin/rails runner "HubKernel::Mcp.check!"`.
  An `UnservableHubError` there lists every problem to fix, one per line: a
  problem hub_kernel-interface's own check finds, a served name holding two
  underscores in a row, a tool name holding a character other than a letter, a
  digit, an underscore or a hyphen, a tool name longer than 64 characters, or a
  browser setting that is not set. A tool name is `<served name>__<method>`.
- Fix a check failure by changing the served name, the hub method or the
  initializer in the host, never by removing the check. Inside `to_prepare` the
  check runs again after every code reload.
- Run the check again whenever the served list changes or a hub gains a method.
- A change to `config/initializers/hub_kernel_mcp.rb` takes effect only after
  the app restarts.
- With discovery installed, check it with
  `curl -i -X POST <host>/mcp` while signed out: the response should be 401 with
  a `WWW-Authenticate` header naming
  `<host>/.well-known/oauth-protected-resource/mcp`, and a GET to that address
  should name the endpoint.
- With the approval page installed, open `<host>/mcp/authorize` in a browser
  while signed out: the host's sign-in should take over. Signed in, a request
  with no registered client and redirect address shows a page saying the app
  asked to send the person to an address it did not register.
- With the token lookup installed, check it with
  `bin/rails runner "p HubKernel::Mcp::Connection.person_for('unknown')"`,
  which should print `nil`, and with `curl -i -X POST <host>/mcp` carrying
  `Authorization: Bearer unknown`, which should answer 401.
- Run `bin/rails hub_kernel_mcp:install:migrations` again after upgrading the
  gem, then `db:migrate`. It copies only migrations the host does not have yet.
  A host that installed an earlier version with two or three migrations gets
  the missing ones this way, and the token address answers with an error until
  they are run.
- An access token lasts one hour. A refresh token lasts ninety days from when
  it was issued, works only for the client it was issued to, and works once:
  trading it retires it and the access token issued with it. A client that
  lets its refresh token expire signs in again through the approval page.
- A token issued before the refresh token migration was run has no refresh
  token, so its client signs in again through the approval page once the
  access token expires.
- Out of scope: choosing which hubs are served and setting permissions and
  account scope, which belong to hub_kernel-interface, and changing what the
  endpoint, the discovery documents or the approval page answer, which belongs
  to `hub_kernel-mcp-develop`.
