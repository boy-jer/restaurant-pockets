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
  "Hello World!"
end

get '/hello/:name' do |n|
    "Hello #{n}"
end