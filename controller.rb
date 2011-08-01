require 'haml'
require 'json'
require 'sass'
require 'sinatra'

require './models'
require './partial'
require './secret'

def copy_hash h 
    h2 = {}
    h.each_pair {|k,v| h2[k] = v }
    h2
end

class RestaurantManager < Sinatra::Base

  enable :static

  set :haml, :format => :html5
  set :root, File.dirname(__FILE__)
  set :public, Proc.new { File.join(root, "static") }

  set :api_key, Secret.google_api_key

  # Pick a restaurant, group size, and time
  get '/' do  
    @restaurants = Restaurant.all
    @times = Restaurant.all_time_strings
    haml :index
  end

  # Detail page for a restaurant
  get '/detail/:restaurant' do
    @restaurant = Restaurant.first(:name => params[:restaurant])
    haml :detail
  end

  get '/reservation/'
  end

  get '/openings/:restaurant/:group' do
    content_type :json
    @restaurant = Restaurant.first(:name => params[:restaurant])
    open_slots = @restaurant.get_open_slots(params[:group])
    { 
      open_slots = []
    }.to_json
  end    
    
end
