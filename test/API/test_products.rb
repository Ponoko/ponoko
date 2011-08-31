require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class Test_API_Products < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_auth = MiniTest::Mock.new
    @ponoko = Ponoko::PonokoAPI.new @test_auth

  end

  def test_api_get_product_list
    @test_auth.expect(:get, @api_responses[:products_200], ['products/'])

    resp = @ponoko.get_products
    
    products = resp['products']

    @test_auth.verify
    assert_equal 2, products.length
    assert_equal "xxx", products.first['name']
  end
  
  def test_api_get_product_404
    @test_auth.expect(:get, @api_responses[:ponoko_404], ['products/bogus_key'])

    assert_raises Ponoko::PonokoAPIError do
      @ponoko.get_products "bogus_key"
    end    

    @test_auth.verify
  end
  
  def test_api_get_product
    @test_auth.expect(:get, @api_responses[:product_200], ['products/2413'])

    resp = @ponoko.get_products "2413"

    product = resp['product']

    @test_auth.verify
    assert_equal "xxx", product['name']
    assert_equal 1, product['designs'].length
    assert_equal "6bb50fd03269012e3526404062cdb04a", product['designs'].first['material_key']
    assert_equal "bottom_new.stl", product['designs'].first['filename']
    assert product['materials_available?']

  end
  
  def test_api_make_a_product_missing_design
    @test_auth.expect :post, @api_responses[:product_missing_design_400], ["products", "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    assert_raises Ponoko::PonokoAPIError do
      @ponoko.post_product({:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref'})
    end

    @test_auth.verify
  end

  def test_api_make_a_product
    @test_auth.expect :post, @api_responses[:post_product_200], ['products', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]
    
    file = File.new(File.dirname(__FILE__) + "/../Fixtures/small.svg")
    resp = @ponoko.post_product({:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref',
                                :designs => {:uploaded_data => file, :ref => '42', :material_key => '6bb50fd03269012e3526404062cdb04a'}})

    @test_auth.verify

    assert_equal 'Product', resp['product']['name']
    assert_equal false, resp['product']['locked?']
    assert_equal "18.86", resp['product']['total_make_cost']['total']
    assert_equal 1, resp['product']['designs'].length
    assert_equal "6bb50fd03269012e3526404062cdb04a", resp['product']['designs'].first['material_key']
    assert_equal "small.svg", resp['product']['designs'].first['filename']
    assert_equal "18.86", resp['product']['designs'].first['make_cost']['total']
    assert_equal "USD", resp['product']['designs'].first['make_cost']['currency']
    
  end
  
  def test_add_image
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/add_image', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    file = File.new(File.dirname(__FILE__) + "/../Fixtures/sample.png")
    resp = @ponoko.add_image()
  end
  
  def test_add_assembly_instructions
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/add_assembly', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    file = File.new(File.dirname(__FILE__) + "/../Fixtures/instructions.txt")
    resp = @ponoko.add_assembly()
  end
  
  def test_add_hardware
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/add_hardware', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    resp = @ponoko.add_hardware  
  end
  
end

