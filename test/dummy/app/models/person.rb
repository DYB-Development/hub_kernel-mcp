class Person
  include GlobalID::Identification

  attr_reader :id

  def self.find(id) = new(id)

  def initialize(id)
    @id = id
  end

  def ==(other) = other.is_a?(Person) && other.id == id
end
