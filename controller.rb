require 'haml'
require 'mongo_mapper'
require 'sinatra'

require './secret'

set :haml, :format => :html5
set :public, File.dirname(__FILE__) + '/static'

MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', 10016)
MongoMapper.database = 'restaurant'
MongoMapper.database.authenticate(Secret.username, Secret.password)

VALID_MINUTES = [0, 30]

def copy_hash h 
    h2 = {}
    h.each_pair {|k,v| h2[k] = v }
    h2
end


# stolen from http://github.com/cschneid/irclogger/blob/master/lib/partials.rb
#   and made a lot more robust by me
# this implementation uses erb by default. if you want to use any other template mechanism
#   then replace `erb` on line 13 and line 17 with `haml` or whatever 
module Sinatra::Partials
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << haml(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      haml(:"#{template}", options)
    end
  end
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


class RestaurantManager < Sinatra::Base

  get '/' do  
    @restaurants = Restaurant.all
    @api_key = Secret.google_api_key
    haml :index
  end

  get '/style.css' do
    render "style.css"
  end

  get '/jquery.ui.datepicker.css' do 
    render 'jquery.ui.datepicker.css'
  end

  post '/add' do
    name = params[:name]
  end

  get '/list' do
    @restaurants = Restaurant.all
    haml :list
  end

  get '/reservation' do
    @group = params[:group]
    @restaurant = Restaurant.first(:name => params[:name])
    time = Time.new(params[:year],
                    params[:month],
                    params[:day],
                    params[:hour],
                    0)
    @reservation = @restaurant.reservations.first(:time => time)
                    
    haml :reservation
  end
    
  get '/detail' do
    @restaurant = Restaurant.first(:name => params[:restaurant_name])
    @group = params[:group]
    
    haml :detail
  end

  post '/reserve/:id/:year/:month/:day/:hour/:minute' do
    @restaurant = Restaurant.first(:id => id)
  end

end
