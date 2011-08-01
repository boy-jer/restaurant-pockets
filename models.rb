require 'mongo_mapper'
require 'set'

require './secret'

MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', 10016)
MongoMapper.database = 'restaurant'
MongoMapper.database.authenticate(Secret.username, Secret.password)

RESERVATION_TIME = 2 * 60 * 60 # 2 hours
ONE_DAY = 24 * 60 * 60

# Pretend this is when all restaurants open and close
START_TIME = 11
END_TIME = 23

# Valid possible reservations.
# Probably should just check when reservations are created.
VALID_MINUTES = [0, 30]

def copy_hash h 
    h2 = {}
    h.each_pair {|k,v| h2[k] = v }
    h2
end

def get_day(time)
  Time.mktime(time.year, time.month, time.day, 0, 0)
end


  

class Restaurant 
  
  include MongoMapper::Document

  key :name, String
  key :tables, Hash

  many :reservations

  # Class methods

  def self.time_tuple_to_string(h,m)
    "%s:%s" % [h, m == 0 ? "00" : "30"]
  end
  def self.get_open_times(s, e)
    # Produce reservation times from start and end times.
    # f(9,19) -> [[9,0], [9,30], ...[18,30]]
    slots = (e-s) * 2
    (0...slots).map {|e| [s + e/2, 30 * (e % 2)] } 
  end

  def self.all_times
    Restaurant.get_open_times(0, 24)
  end

  def self.all_time_strings
    Restaurant.all_times.map {|a,b| Restaurant.time_tuple_to_string(a,b) }
  end

  def self.open_times
    Restaurant.get_open_times(START_TIME, END_TIME)
  end

  def self.open_time_strings
    Restaurant.open_times.map {|a,b| Restaurant.time_tuple_to_string(a,b) }
  end


  # Public methods
  def open_slots
    Restaurant.open_times
  end

  def available_slots group, time
    self.open_slots - self.unavailable_slots(group, time)
  end

  def unavailable_slots group, time
    if self.table_exists? group
      self.reservations_for_day(time).find_all {|r| r.no_table? group }.map {|e| [e.hour, e.min] }
    else
      self.open_slots
    end
  end

  # Check that a table is available for the necessary length of time.
  def is_available?(group, time)
    self.open_slots.include? [time.hour, time.min] and 
      self.get_reservations(time).reduce {|acc, res| acc and res.open_table? group }
      
  end

  def reserve(group, time)
    if self.is_available? group, time
      times = self.reservation_times time
      times.each { |time|
        r = self.get_or_create_reservation time
        r.increment group
      }
      true
    else
      false
    end
  end


  def table_exists? group
    self.tables.has_key? group
  end
  

  # Internal methods
  def get_reservations time
    reservation_times = Set.new(self.reservation_times time)
    reservations = Reservation.where(:restaurant_id => self.id, 
                                     :time => { "$gt" => time, "$lt" => time + RESERVATION_TIME })
    # Sometimes reservations should be less than 4, e.g. when the reservation is made an hour before closing.
    # Unless we just create those and never use them?
    if reservations.count < 4
      uncreated = reservation_times - reservations.map {|e| [e.time.hour, e.time.min] }
      uncreated.each { |t| self.get_or_create_reservation t }
      self.get_reservations time
    elsif reservations.count > 4
      raise "There should not be more than 4"
    else
      reservations
    end
  end

  def reservations_for_day time
    start_day = get_day(time)
    end_day = start_day + ONE_DAY
    self.reservations.where(:time => { "$gte" => start_day, "$lt" => end_day })
  end

  def reservation_times(time)
    (0...4).map {|min| time + min * 30 }
  end

  def get_or_create_reservation time
    r = self.reservations.first(:time => time)
    unless r
      r = self.create_reservation time
    end
    r
  end

  def create_reservation time
    self.reservations.create({:time => time, 
                              :tables => self.make_blank_tables})
  end

  def get_tables
    copy_hash self.tables
  end

  def make_blank_tables
    self.get_tables.merge(self.get_tables){ 0 }
  end

end


class Reservation

  include MongoMapper::Document

  key :time, Time
  key :tables, Hash

  belongs_to :restaurant

  def free_tables group
    total_tables = self.restaurant.tables[group]
    reserved_tables = self.tables[group]
    return total_tables - reserved_tables
  end

  def table_exists? group
    self.tables.has_key? group
  end

  def open_table? group
    self.table_exists? group and self.free_tables(group) > 0
  end

  def no_table? group
    not self.open_table? group
  end

  # Increase the group number in self.tables by 1.
  def increment group 
    # Hashes are apparently static?
    # Need to experiment more.
    val = self.tables[group]
    self.tables[group] = val + 1
    self.save()
  end

  # Necessary?
  def nearby_reservations count
    times = (-count..count).map {|i| self.time + 30 * 60 * i }
    times.map {|t| Reservation.first(:time => time) }
  end


end


