module BackOffice
  extend HubKernel::Exposes

  exposes :close_books, takes: [], writes: true

  def self.close_books = "closed"
end
