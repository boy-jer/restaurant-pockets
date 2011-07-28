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
end
