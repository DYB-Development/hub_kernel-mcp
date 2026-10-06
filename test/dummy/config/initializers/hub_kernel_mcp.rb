HubKernel::Mcp.base_controller = "ApiController"
HubKernel::Mcp.person_method = :current_person
HubKernel::Mcp.account_method = :current_account

Rails.application.config.to_prepare do
  HubKernel::Interface.hubs = [ Shop, { "money" => Ledger } ]
  HubKernel::Authz.check = ->(person, action, _account) { person == "sam" || action == "shop:price_of" }
  HubKernel::Context.scope = ->(_account, &call) { call.call }
end
