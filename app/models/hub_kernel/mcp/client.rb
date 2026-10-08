module HubKernel
  module Mcp
    class Client < ActiveRecord::Base
      has_secure_token :uid
    end
  end
end
