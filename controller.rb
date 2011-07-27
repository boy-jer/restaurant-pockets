require 'sinatra'

get '/' do
  "Hello World!"
end

get '/hello/:name' do |n|
    "Hello #{n}"
end