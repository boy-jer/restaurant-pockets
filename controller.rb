require 'haml'
require 'json'
require 'sass'
require 'set'
require 'sinatra'

require './models'
require './partial'

class FakeTableApplication < Sinatra::Base

  enable :static

  set :haml, :format => :html5
  set :root, File.dirname(__FILE__)
  set :public, Proc.new { File.join(root, "static") }

  set :api_key, ENV['sinatra_google_api_key']

  # Pick a restaurant, group size, and time
  get '/' do  
    @restaurants = Restaurant.all
    haml :index
  end

  # Detail page for a restaurant
  get '/detail/:restaurant' do
    @restaurant = Restaurant.first(:name => params[:restaurant])
    haml :detail
  end

  # The real page.
  get '/reservation/' do
    @restaurant = Restaurant.first(:name => params[:restaurant])
    month, day, year = params[:date].split("/")
    @group = params[:group]
    @this_day = Time.mktime(year, month, day)
    available = Set.new(@restaurant.available_slots(@group, @this_day))
    z = Restaurant.open_time_strings.zip(Restaurant.open_times)
    @slot_map = z.map {|str, arr| [str, available.include?(arr) ] }
    haml :reservation
  end

  get '/openings/:restaurant/:group/:date/' do
    content_type :json
    @restaurant = Restaurant.first(:name => params[:restaurant])
    open_slots = @restaurant.get_open_slots(params[:group])
    {
      :open_slots => [],
    }.to_json
  end    

  get '/add/restaurant/' do
    haml :add_restaurant
  end

  post '/add/restaurant/' do 
    redirect '/'
  end

    
end
