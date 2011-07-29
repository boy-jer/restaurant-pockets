require 'sinatra'
require 'mongo'
require 'haml'

set :haml, :format => :html5

get '/' do  
  @this = "Can you do it?"
  @lst = (41...47)
  haml :index
end

post '/add' do
  name = params[:name]
end
