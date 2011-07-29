require 'sinatra'
require 'mongo_mapper'
require 'haml'
require './secret'

set :haml, :format => :html5

MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', 10016)
MongoMapper.database = 'restaurant'
MongoMapper.database.authenticate(Secret.username, Secret.password)


get '/' do  
  @this = "Can you do it?"
  @lst = (41...47)
  haml :index
end

post '/add' do
  name = params[:name]
end
