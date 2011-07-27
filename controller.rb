require 'rubygems'
require 'sinatra'
require 'datamapper'


DataMapper::Database.setup({
  :adapter  => 'sqlite3',
  :host     => 'localhost',
  :username => '',
  :password => '',
  :database => 'db/restaurant_development'
})

get '/' do
    'Hello from Sinatra on Heroku'
end

get '/restaurants' do
  @restaurants = Restaurant.all
  haml view :restaurants
end

get '/restaurant/detail/:id' do
  @restaurant = Restaurant.find :id => params[:id]
  haml view :restaurant_detail
end

get '/restaurant/reserve/:table_id' do
  @table = Table.find :id => params[:table_id]
  haml view :reserve
end
