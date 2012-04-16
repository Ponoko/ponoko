require 'test_helper'

class TestOrders < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_api = MiniTest::Mock.new
    Ponoko.api = @test_api
  end
  
  def test_get_orders
    @test_api.expect(:send, 
                     make_resp(:orders_200), 
                     ['get_orders', nil])

    orders = Ponoko::Order.get!

    @test_api.verify
    assert_equal 1, orders.length
    assert_equal "4321", orders.first.ref
    assert orders.first.shipped?
  end

  def test_get_an_order
    @test_api.expect(:send, 
                     make_resp(:order_200), 
                     ['get_orders', 'order_key'])

    order = Ponoko::Order.get! "order_key"

    @test_api.verify
    assert_equal "order_key", order.key
    refute order.shipped?
#    assert_equal 1, order.quantity
#    assert_equal 'USD', order.currency
    assert_equal [{"key"=>"1234", "ref"=>"4321", "quantity"=>1}], order.products
    assert_equal [{"name"=>"design_checked", "completed_at"=>"2011/01/01 12:00:00 +0000"}], order.events
    assert_equal 'design_checked', order.status

  end

  def test_address_to_hash
    address = Ponoko::Address[{"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}]
    assert_equal({"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}, address.to_params)
    
#     assert_equal "John", address.first_name
#     assert_equal "Te Aro", address.address_line_2
  end
  
  def test_shipping_options
    @test_api.expect(:get_shipping_options, 
                      make_resp(:shipping_200), 
                      [{'ref' => 'order_ref', 
                        'products' => [{'key' => '1234', 'quantity' => "1"},{'key' => 'abcdef', 'quantity' => "99"}], 
                        'delivery_address' => {'first_name' => 'John', 'last_name' => 'Brown', 'address_line_1' => '27 Dixon Street', 'address_line_2' => 'Te Aro', 'city' => 'Wellington', 'state' => 'na', 'zip_or_postal_code' => '6021', 'country' => 'New Zealand', "phone_number" => "045678910"}}])
                     
    product1 = Ponoko::Product.new 'key' => '1234'
    product2 = Ponoko::Product.new 'key' => 'abcdef'
    order = Ponoko::Order.new 'ref' => "order_ref"
    
    order.add_product product1, 1
    order.add_product product2, 99
    
    order.delivery_address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}

    shipping_options = order.shipping_options!

    @test_api.verify
    assert_equal [{"code"=>"ups_ground", "name"=>"UPS Ground", "price"=>"56.78"}], shipping_options
  end
  
  def test_shipping_options_address_fail
    order = Ponoko::Order.new

    e = assert_raises Ponoko::PonokoAPIError do
      order.shipping_options!
    end
    
    assert_equal "Order must have a Delivery Address", e.message
  end
  
  def test_shipping_options_fail
    @test_api.expect(:get_shipping_options, 
                      @api_responses[:shipping_options_error],
                      [{'ref' => 'order_ref', 
                        'products' => [{'key' => '1234', 'quantity' => "1"},{'key' => 'abcdef', 'quantity' => "99"}], 
                        'delivery_address' => {'first_name' => 'John', 'last_name' => 'Brown', 'address_line_1' => '27 Dixon Street', 'address_line_2' => 'Te Aro', 'city' => 'Wellington', 'state' => 'na', 'zip_or_postal_code' => '6021', 'country' => 'New Zealand', "phone_number" => "045678910"}}])

  
    product1 = Ponoko::Product.new 'key' => '1234'
    product2 = Ponoko::Product.new 'key' => 'abcdef'
    order = Ponoko::Order.new 'ref' => "order_ref"
    
    order.add_product product1, 1
    order.add_product product2, 99
    
    order.delivery_address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}

    error = order.shipping_options!
  
    @test_api.verify
    assert error.is_a? Ponoko::Error
  end
  
  def test_make_an_order_with_no_params
    order = Ponoko::Order.new
    
    e = assert_raises Ponoko::PonokoAPIError do
      order.send!
    end

    assert_equal "Order must have a Delivery Address", e.message
  end
  
  def test_make_an_order_with_no_products
    address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}
    order = Ponoko::Order.new 'delivery_address' => address,  'shipping_option_code' => 'ups_ground'
    
    e = assert_raises Ponoko::PonokoAPIError do
      order.send!
    end

    assert_equal "Order must have Products", e.message
  end
  
  def test_make_an_order_with_no_address
    order = Ponoko::Order.new 'shipping_option_code' => 'ups_ground'
    product = Ponoko::Product.new 
    order.add_product product
    
    e = assert_raises Ponoko::PonokoAPIError do
      order.send!
    end
    
    assert_equal "Order must have a Delivery Address", e.message
  end
  
  def test_make_an_order_with_no_shipping_option
    address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}

    order = Ponoko::Order.new 'delivery_address' => address
    product = Ponoko::Product.new
    order.add_product product
    
    e = assert_raises Ponoko::PonokoAPIError do
      order.send!
    end

    assert_equal "Order must have a Shipping Option Code", e.message
  end
  
  def test_make_an_order
    @test_api.expect(:post_order, 
                     make_resp(:make_200),
                     [{"ref"=>"order_ref", "products"=>[{"key"=>"product_key", "quantity"=>"99"}], "shipping_option_code"=>"ups_ground", "delivery_address"=>{"first_name"=>"John", "last_name"=>"Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}}])

    address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}

    order = Ponoko::Order.new 'ref' => 'order_ref', 'delivery_address' => address, 'shipping_option_code' => 'ups_ground'
    product = Ponoko::Product.new 'key' => "product_key"
    order.add_product product, 99

    assert_nil order.key

    order.send!

    @test_api.verify
    
    assert_equal 'order_key', order.key
    assert_equal 'order_ref', order.ref
    assert_equal 56.78, order.make_cost
    assert_equal 56.78, order.material_cost
    assert_equal 56.78, order.shipping_cost
    assert_equal 56.78, order.total_cost
#     assert_equal 1, order.quantity
#     assert_equal 'USD', order.currency
  end
  
  def test_update_order
=begin
    @test_api.verify

=end
  end

  def test_bump_order_state
    @test_api.expect :step_order, make_resp(:bump_order), ['order_key']

    order = Ponoko::Order.new 'key' => 'order_key'
    
    Ponoko::Sandbox::step_order order

    @test_api.verify
    assert_equal "order_key", order.key
    refute order.shipped?
    assert_equal "design_checked", order.status
  end
  
  def test_order_status
    @test_api.expect :get_order_status, make_resp(:status), ['order_key']

    order = Ponoko::Order.new 'key' => 'order_key'    
    status = order.status

    @test_api.verify
    assert_equal 'design_checked', status
    refute order.shipped?
    assert_equal 'order_key', order.key
    assert_equal 'design_checked', status
    assert_equal 'design_checked', order.status
    assert_equal [{'name' => 'design_checked', 'completed_at' => '2011/01/01 12:00:00 +0000'}], order.events
    assert_equal ['xxx-yyy'], order.tracking_numbers
    assert_equal 'ups_ground', order.shipping_option_code
    assert_equal '2011/01/01 12:00:00 +0000', order.last_successful_callback_at
  end

  def test_order_status_bang
    @test_api.expect :get_order_status, make_resp(:status), ['order_key']

    order = Ponoko::Order.new 'key' => 'order_key'    
    status = order.status!

    @test_api.verify
    assert_equal 'design_checked', status
    assert_equal [{'name' => 'design_checked', 'completed_at' => '2011/01/01 12:00:00 +0000'}], order.events
  end

  def test_order_status_error
    @test_api.expect :get_order_status, make_resp(:ponoko_404), ['bogus_key']

    order = Ponoko::Order.new 'key' => 'bogus_key'    
    status = order.status

    @test_api.verify
    assert_equal 'Not Found. Unknown key', status.message

  end

end
