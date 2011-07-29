require 'sinatra'
require 'mongo_mapper'
require 'haml'
require './secret'

set :haml, :format => :html5

MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', 10016)
MongoMapper.database = 'restaurant'
MongoMapper.database.authenticate(Secret.username, Secret.password)

def hash_keys_to_str(h)
  h2 = {}
  h.each_pair {|k,v| h2[k.to_s] = v }
  h2
end

def hash_keys_to_int(h)
  h2 = {}
  h.each_pair {|k,v| h2[k.to_i] = v }
  h2
end

class Restaurant 
  include MongoMapper::Document

  key :name, String
  key :tables, Hash

  many :reservations


end

class Fake

  def get_tables
    hash_keys_to_int(self.tables)
  end


    

  def make_blank_tables
    self.tables.merge(self.tables){ 0 }
  end

  def has_table? count
    self.tables.has_key? count
  end

  def create_reservation time
    self.reservations.create({:time => time, 
                              :tables => self.make_blank_tables})
  end

  def get_reservation time
    self.reservation.first(:time => time)
  end

  def check_time time
    [0, 30].include? time.min
  end
    
  def get_open_for_time time
    r = self.reservations.first(:time => time)
    self.get_open r
  end

  def get_open reservation
    self.tables.merge(reservation.tables){|k, old, new| new - old}
  end

  def is_open(time, count)
    r = self.reservations.first(:time => time)
    !!self.get_open(r).count # Coerce boolean
  end

  def reserve(time, count)
    if check_time(time)
      r = self.reservations.first(:time => time)
      unless r
        r = self.create_reservation time
      end
      r.tables[count] = r.tables.fetch(count, 0) + 1
      true
    end
    false
    
  end
    
end



class Reservation
  include MongoMapper::Document

  key :time, Time
  key :tables, Hash

  belongs_to :restaurant


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



