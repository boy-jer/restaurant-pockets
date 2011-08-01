require './controller'
require 'test/unit'
require 'rack/test'

set :environment, :test

class FakeTableTest < Test::Unit::TestCase
  include Rack::Test::Methods # Look a mixin!

  def app
    FakeTableApplication
  end

  def test_home_ok
    get '/'
    assert last_response.ok?
  end

  def test_detail_ok
    get '/detail/Home/'
    assert last_response.ok?
  end

  def test_restaurant_exists
    assert_not_nil Restaurant.first
  end

  def test_restaurant_open_slots
    open_slots = [
                  [11, 0], [11, 30], [12, 0], [12, 30], [13, 0], [13, 30], [14, 0], [14, 30], 
                  [15, 0], [15, 30], [16, 0], [16, 30], [17, 0], [17, 30], [18, 0], [18, 30], 
                  [19, 0], [19, 30], [20, 0], [20, 30], [21, 0], [21, 30], [22, 0], [22, 30]
                  ]
    assert_equal Restaurant.first.open_slots, open_slots
  end

end

