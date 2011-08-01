require 'mongo_mapper'

require './secret'

MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', 10016)
MongoMapper.database = 'restaurant'
MongoMapper.database.authenticate(Secret.username, Secret.password)


START_TIME = 12
END_TIME = 22

VALID_MINUTES = [0, 30]

def tuple_to_time_string(h,m)
  "%s:%s" % [h, m == 0 ? "00" : "30"]
end
  
class Restaurant 
  
  include MongoMapper::Document

  key :name, String
  key :tables, Hash

  many :reservations

  # Class methods
  def self.all_times
    Restaurant.get_open_times(0, 48)
  end

  def self.all_time_strings
    Restaurant.all_times.map {|a,b| tuple_to_time_string(a,b) }
  end

  def self.get_open_times(s, e)
    (s...e).map {|e| [s + e/2, 30 * (e % 2)] }
  end

  def self.get_open_time_strings(s, e)
    Restaurant.get_open_times(s,e).map {|a,b| tuple_to_time_string(a,b) }
  end
  
  # Instance functions
  def open_times
    Restaurant.get_open_times(START_TIME, END_TIME)
  end

  def open_time_strings
    Restaurant.get_open_time_strings(START_TIME, END_TIME)
  end

  def get_tables
    copy_hash self.tables
  end

  def make_blank_tables
    self.get_tables.merge(self.get_tables){ 0 }
  end

  def get_or_create_reservation time
    r = self.reservations.first(:time => time)
    unless r
      r = self.create_reservation time
    end
  end


  def create_reservation time
    self.reservations.create({:time => time, 
                              :tables => self.make_blank_tables})
  end

  def valid_time? time
    VALID_MINUTES.include? time.min
  end


  def get_open reservation
    reservation_tables = copy_hash reservation.tables
    self.get_tables.merge(reservation_tables){|k, old, new| old - new}
  end


  def meal_times start
    [0,30,60,90].map {|min| start + min * 60 }
  end

  def open_table? (time, group)
    r = self.get_or_create_reservation time
    self.get_open(r)[group] > 0
  end
  
  def open_tables? (times, group)
    times.reduce(true) {|acc, time| acc and self.open_table?(time, group)}
  end

  def can_reserve? (time, group)
    times = self.meal_times time
    self.has_table? group and self.open_tables? times, group
  end
  
  def reserve(time, group)
    # Check that
    # 1. Time is valid
    # 1. Restaurant can seat the table for needed times.
    if self.can_reserve? time, group
      times = self.meal_times time
      times.each { |time|
        r = self.get_or_create_reservation time
        r.increment group
      }
      true
    else
      false
    end
  end


end


class Reservation
  include MongoMapper::Document

  key :time, Time
  key :tables, Hash

  belongs_to :restaurant

  def has_table? group
    self.tables.has_key? group
  end


  def nearby_reservations count
    times = (-count..count).map {|i| self.time + 30 * 60 * i }
    times.map {|t| Reservation.first(:time => time) }
  end


  def is_free? group
    self.has_table? group and self.resertaurant.get_open(self)[group] > 0
  end
    

  def increment group 
    # Watch out! hashes are apparently static.
    val = self.tables[group]
    self.tables[group] = val + 1
    self.save()
  end

end


