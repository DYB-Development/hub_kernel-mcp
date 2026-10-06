module Ledger
  extend HubKernel::Exposes

  exposes :record_spend, takes: %i[amount], writes: true

  def self.record_spend(amount:) = amount
end
