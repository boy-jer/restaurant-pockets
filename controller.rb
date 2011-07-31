require 'haml'
require 'sass'
require 'sinatra'

require './models'
require './secret'


VALID_MINUTES = [0, 30]

def copy_hash h 
    h2 = {}
    h.each_pair {|k,v| h2[k] = v }
    h2
end


# stolen from http://github.com/cschneid/irclogger/blob/master/lib/partials.rb
#   and made a lot more robust by me
# this implementation uses erb by default. if you want to use any other template mechanism
#   then replace `erb` on line 13 and line 17 with `haml` or whatever 
module Sinatra::Partials
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << haml(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      haml(:"#{template}", options)
    end
  end
end


class RestaurantManager < Sinatra::Base

  enable :static

  set :haml, :format => :html5
  set :root, File.dirname(__FILE__)
  set :public, Proc.new { File.join(root, "static") }

  get '/' do  
    @times = []
    @api_key = Secret.google_api_key
    @restaurants = Restaurant.all
    @files = settings.public
    @flies = "flos"
    @settings = settings
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
