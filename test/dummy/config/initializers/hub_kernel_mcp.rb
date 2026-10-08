HubKernel::Mcp.base_controller = "ApiController"
HubKernel::Mcp.person_method = :current_person
HubKernel::Mcp.account_method = :current_account
HubKernel::Mcp.browser_controller = "BrowserController"
HubKernel::Mcp.sign_in_method = :sign_in_person
HubKernel::Mcp.browser_person_method = :signed_in_person
HubKernel::Mcp.browser_layout = "application"

Rails.application.config.to_prepare do
  HubKernel::Interface.hubs = [ Shop, { "money" => Ledger } ]
  HubKernel::Authz.check = ->(person, action, _account) { person == "sam" || action == "shop:price_of" }
  HubKernel::Context.scope = ->(_account, &call) { call.call }
end
