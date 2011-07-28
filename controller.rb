require 'sinatra'
require 'mongo'
require 'haml'

set :haml, :format => :html5

get '/' do  
  test = "Can you do it?"
  lst = [41...47]
  haml :index
end

get '/hello/:name' do |n|
    "Hello #{n}"
end


post '/add' do
  name = params[:name]
end
