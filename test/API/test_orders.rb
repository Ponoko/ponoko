require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class Test_API_Orders < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_auth = MiniTest::Mock.new
    @ponoko = Ponoko::PonokoAPI.new @test_auth
  end

  def test_api_get_order_list
    @test_auth.expect(:get, @api_responses[:orders_200], ['orders/'])

    resp = @ponoko.get_orders
    
    orders = resp['orders']
    @test_auth.verify
    assert_equal 1, orders.length
    assert_equal "4321", orders.first['ref']
    assert orders.first['shipped']
  end
  
  def test_api_get_order_404
    @test_auth.expect(:get, @api_responses[:ponoko_404], ['orders/bogus_key'])

    assert_raises Ponoko::PonokoAPIError do
      @ponoko.get_orders "bogus_key"
    end    

    @test_auth.verify
  end
  
  def test_api_get_order
    @test_auth.expect(:get, @api_responses[:order_200], ['orders/2413'])

    resp = @ponoko.get_orders "2413"

    order = resp['order']
    @test_auth.verify
    assert_equal "order_key", order['key']
    assert ! order['shipped']
    assert_equal [{"key"=>"1234", "ref"=>"4321", "quantity"=>1}], order['products']
    assert_equal [{"name"=>"design_checked", "completed_at"=>"2011/01/01 12:00:00 +0000"}], order['events']
  end
  
  def test_shipping_options
    @test_auth.expect(:get, 
                     @api_responses[:shipping_200], 
                     ["orders/shipping_options?products[][key]=1234&products[][quantity]=1&products[][key]=abcdef&products[][quantity]=99&delivery_address[address_line_1]=27 Dixon Street&delivery_address[address_line_2]=Te Aro&delivery_address[city]=Wellington&delivery_address[state]=na&delivery_address[zip_or_postal_code]=6021&delivery_address[country]=New Zealand"])
    
    resp = @ponoko.get_shipping_options({'products' => [{'key' => '1234', 'quantity' => '1'}, {'key' => 'abcdef', 'quantity' => '99'}],
                                         'delivery_address' => {'address_line_1' => '27 Dixon Street', 'address_line_2' => 'Te Aro', 'city' => 'Wellington', 'state' => 'na', 'zip_or_postal_code' => '6021', 'country' => 'New Zealand'}})

    @test_auth.verify
    shipping_options = resp['shipping_options']
    assert_equal 2, shipping_options['products'].length
    assert_equal 1, shipping_options['options'].length
    assert_equal "UPS Ground", shipping_options['options'].first['name']
    assert_equal "56.78", shipping_options['options'].first['price']
  end
  
  def test_shipping_options_fail
    @test_auth.expect(:get, 
                     @api_responses[:ponoko_404],
                     ["orders/shipping_options?delivery_address[address_line_1]=27%20Dixon%20Street&delivery_address[address_line_2]=Te%20Aro&delivery_address[city]=Wellington&delivery_address[state]=na&delivery_address[zip_or_postal_code]=6021&delivery_address[country]=New%20Zealand"])

    assert_raises Ponoko::PonokoAPIError do
      @ponoko.get_shipping_options({})
    end
  end
  
  def test_make_an_order
    @test_auth.expect(:post, @api_responses[:make_200], ['orders', "ref=order_ref&products[key]=product_key&products[quantity]=99&shipping_option_code=ups_ground&delivery_address[city]=New Orleans&delivery_address[country]=United States&delivery_address[phone_number]=504-680-4418&delivery_address[address_line_1]=643 Magazine St., Suite 405&delivery_address[zip_or_postal_code]=70130&delivery_address[address_line_2]=&delivery_address[last_name]=Reily&delivery_address[state]=LA&delivery_address[first_name]=William"])

    resp = @ponoko.post_order({'ref' => 'order_ref', 
                              'products' => {'key' => 'product_key', 'quantity' => '99'}, 
                              'shipping_option_code' => 'ups_ground', 
                              "delivery_address"=> {"city"=>"New Orleans",
                                                   "country"=>"United States",
                                                   "phone_number"=>"504-680-4418",
                                                   "address_line_1"=>"643 Magazine St., Suite 405",
                                                   "zip_or_postal_code"=>"70130",
                                                   "address_line_2"=>"",
                                                   "last_name"=>"Reily",
                                                   "state"=>"LA",
                                                   "first_name"=>"William"}})

    order = resp['order']
    @test_auth.verify
    assert_equal "order_key", order['key']
    assert_equal "order_ref", order['ref']
    assert_equal false, order['shipped']
    assert_equal [{"key"=>"1234", "ref"=>"4321", "quantity"=>1}], order['products']
    assert_equal [{"name"=>"design_checked", "completed_at"=>"2011/01/01 12:00:00 +0000"}], order['events']
  end
  
  def test_bump_order_state
    @test_auth.expect(:get, @api_responses[:order_200], ['orders/trigger-next-event/order_key'])

    resp = @ponoko.step_order 'order_key'

    order = resp['order']
    @test_auth.verify
    assert_equal "order_key", order['key']
    assert_equal false, order['shipped']
    assert_equal [{"key"=>"1234", "ref"=>"4321", "quantity"=>1}], order['products']
    assert_equal [{"name"=>"design_checked", "completed_at"=>"2011/01/01 12:00:00 +0000"}], order['events']
  end
  
  def test_bump_order_state_not_on_sandbox
    ponoko = Ponoko::PonokoAPI.new @test_auth, :production
    
    assert_raises Ponoko::PonokoAPIError do
      ponoko.step_order 'order_key'
    end
    
    @test_auth.verify
  end
  
  def test_order_status
    @test_auth.expect(:get, @api_responses[:status], ['orders/status/order_key'])

    resp = @ponoko.get_order_status 'order_key'
    
    order = resp['order']
    @test_auth.verify
    assert_equal "order_key", order['key']
    assert_equal false, order['shipped']
  end
  
end
