module Shop
  extend HubKernel::Exposes

  exposes :price_of, takes: %i[item], writes: false
  exposes :restock, takes: %i[item count], writes: true

  def self.price_of(item:) = "#{item} costs 3"

  def self.restock(item:, count:) = "#{count} #{item} restocked"
end
