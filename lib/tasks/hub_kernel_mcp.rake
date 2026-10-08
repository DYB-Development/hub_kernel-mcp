namespace :hub_kernel_mcp do
  desc "Remove expired authorization codes, connections that can no longer be used, and clients with no connection older than a day"
  task prune: :environment do
    HubKernel::Mcp::Prune.call
  end
end
