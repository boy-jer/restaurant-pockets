require 'sinatra'
require 'mongo'
require 'haml'


get '/' do  
  haml :index
end

get '/hello/:name' do |n|
    "Hello #{n}"
end


post '/add' do
  name = params[:name]
  db = Mongo::Connection.new("staff.mongohq.com/restaurant", 10016).db("database")
  auth = db.authenticate("chris", "password")
  coll = db.collection("restaurants")
  doc = {"name" => name}
  coll.insert(doc)
  if request.xhr?
    "true"
  else
    "We've added your restaurant"
  end
end
