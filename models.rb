class Restaurant < DataMapper::Base
  property :name, :text
end

class Table < DataMapper::Base
  property :size, :integer
  property :restaurant, :relation
end

class Reservation < DataMapper::Base
  property :table, :relation
  property :start, :datetime
end
