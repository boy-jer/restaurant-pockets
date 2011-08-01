require 'haml'
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

  get '/' do  
    @restaurants = Restaurant.all
    @times = Restaurant.all_times
    haml :index
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
