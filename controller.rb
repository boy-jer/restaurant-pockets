require 'sinatra'
require 'mongo_mapper'
require 'haml'
require './secret'

set :haml, :format => :html5

MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', 10016)
MongoMapper.database = 'restaurant'
MongoMapper.database.authenticate(Secret.username, Secret.password)

def copy_hash h 
    h2 = {}
    h.each_pair {|k,v| h2[k] = v }
    h2
end


class Restaurant 
  include MongoMapper::Document

  key :name, String
  key :tables, Hash

  many :reservations


  def get_tables
    copy_hash self.tables
  end

  def make_blank_tables
    self.get_tables.merge(self.get_tables){ 0 }
  end

  def create_reservation time
    self.reservations.create({:time => time, 
                              :tables => self.make_blank_tables})
  end

  def valid_time? time
    [0, 30].include? time.min
  end

  def has_table? group
    self.tables.has_key? group
  end

  def get_open reservation
    reservation_tables = copy_hash reservation.tables
    self.get_tables.merge(reservation_tables){|k, old, new| old - new}
  end


  def meal_times start
    [0,30,60,90].map {|min| start + min * 60 }
  end

  def open_table? (time, group)
    r = self.reservations.first(:time => time)
    unless r
      r = self.create_reservation time
    end
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
        r = self.reservations.first(:time => time)
        unless r
          r = self.create_reservation time
        end
        # Complicated because hashes are apparently static.
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

  def increment group 
    val = self.tables[group]
    self.tables[group] = val + 1
    self.save()
  end


end


class RestaurantManager < Sinatra::Base

  get '/' do  
    @restaurants = Restaurant.all
    haml :index
  end

  post '/add' do
    name = params[:name]
  end

  get '/list' do
    @restaurants = Restaurant.all
    haml :list
  end

  get '/detail/:name' do
    @restaurant = Restaurant.first(:name => :name)
    haml :detail
  end

  post '/reserve/:id/:year/:month/:day/:hour/:minute' do
    @restaurant = Restaurant.first(:id => id)
  end

end



