require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class TestAPIProducts < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_auth = MiniTest::Mock.new
    @ponoko = Ponoko::PonokoAPI.new @test_auth

  end

  def test_api_get_product_list
    @test_auth.expect :get, @api_responses[:products_200], ['products/']

    resp = @ponoko.get_products
    
    products = resp['products']

    @test_auth.verify
    assert_equal 2, products.length
    assert_equal "xxx", products.first['name']
  end
  
  def test_api_get_product_404
    @test_auth.expect :get, @api_responses[:ponoko_404], ['products/bogus_key']

    resp = @ponoko.get_products "bogus_key"

    assert_equal 'error', resp.keys.first
    @test_auth.verify
  end
  
  def test_api_get_product
    @test_auth.expect :get, @api_responses[:product_200], ['products/2413']

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
    @test_auth.expect :post, @api_responses[:product_missing_design_400], ["products", {:name=>"Product", :notes=>"This is a product description", :ref=>"product_ref"}, :multipart]

    resp = @ponoko.post_product({:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref'})

    assert_equal 'error', resp.keys.first
    @test_auth.verify
  end

  def test_api_make_a_product
    file = File.new(File.dirname(__FILE__) + "/../fixtures/small.svg")

    @test_auth.expect :post, @api_responses[:post_product_200], ["products", {:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref', :designs => [{"file_name"=>"small.svg", 'uploaded_data' => file, 'ref' => '42', 'material_key' => '6bb50fd03269012e3526404062cdb04a'}]}, :multipart]
    
    resp = @ponoko.post_product({:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref',
                                :designs => [{'file_name' => 'small.svg', 'uploaded_data' => file, 'ref' => '42', 'material_key' => '6bb50fd03269012e3526404062cdb04a'}]})

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
  
  def test_delete_product
    @test_auth.expect :post, @api_responses[:product_delete], ['products/delete/2413', {}]

    @ponoko.delete_product "2413"

    @test_auth.verify
  end
  
  def test_add_design
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/2413/add_design", {}, :multipart]
    resp = @ponoko.post_design "2413", {}
    @test_auth.verify
  end
  
  def test_update_design
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/2413/update_design", {}, :multipart]
    resp = @ponoko.update_design "2413", {}
    @test_auth.verify
  end
  
  def test_replace_design
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/2413/replace_design", {}, :multipart]
    resp = @ponoko.replace_design "2413", {}
    @test_auth.verify
  end
  
  def test_destroy_design
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/2413/delete_design", "666"]
    resp = @ponoko.destroy_design "2413", "666"
    @test_auth.verify
  end
  
  def test_add_design_image
    image_file_default = File.new(File.dirname(__FILE__) + "/../fixtures/lamp-1_product_page.jpg")
    image_file = File.new(File.dirname(__FILE__) + "/../fixtures/3d-1_product_page.jpg")

    @test_auth.expect :post, @api_responses[:post_product_200], ['products/2413/design_images/', {'design_images' => [{'uploaded_data' => image_file_default, 'default' => true}]}, :multipart]
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/2413/design_images/', {'design_images' => [{'uploaded_data' => image_file}]}, :multipart]


    resp = @ponoko.post_design_image "2413", {'design_images' => [{'uploaded_data' => image_file_default, 'default' => true}]}
    resp = @ponoko.post_design_image "2413", {'design_images' => [{'uploaded_data' => image_file}]}

    @test_auth.verify
  end
  
  def test_get_design_image
    @test_auth.expect :get, @api_responses[:image_200], ['products/2413/design_images/download?filename=lamp-1_product_page.jpg']
    resp = @ponoko.get_design_image "2413", "lamp-1_product_page.jpg"
    @test_auth.verify
    assert_equal "The contents of an image file", resp
  end
  
  def test_destroy_design_image
    @test_auth.expect(:post, @api_responses[:product_200], ['products/2413/design_images/destroy',{'filename' => 'lamp-1_product_page.jpg'}])
    resp = @ponoko.destroy_design_image "2413", "lamp-1_product_page.jpg"
    @test_auth.verify
  end
  
  def test_add_assembly_instructions_file
    file = File.new(File.dirname(__FILE__) + "/../fixtures/instructions.txt")
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/2413/assembly_instructions/", {'assembly_instructions' => [{'uploaded_data' => file}]}, :multipart]
    resp = @ponoko.post_assembly_instructions_file "2413", {'assembly_instructions' => [{'uploaded_data' => file}]}
    @test_auth.verify
  end
  
  def test_add_assembly_instructions_url
    url = 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/2413/assembly_instructions/", {'assembly_instructions' => [{"file_url" => url}]}]
    resp = @ponoko.post_assembly_instructions_url '2413', {'assembly_instructions' => [{"file_url" => url}]}
    @test_auth.verify
  end
  
  def test_get_assembly_instructions_file
    @test_auth.expect :get, @api_responses[:assembly_200], ['products/2413/assembly_instructions/download?filename=instructions.txt']
    resp = @ponoko.get_assembly_instructions "2413", "instructions.txt"
    @test_auth.verify
    assert_equal "The contents of a file", resp
  end
  
  def test_get_assembly_instructions_url
    skip "Not implemented"
    assert false
  end
  
  def test_destroy_assembly_instructions_file
    @test_auth.expect :post, @api_responses[:product_200], ['products/2413/assembly_instructions/destroy', {'filename' => 'instructions.txt'}]
    resp = @ponoko.destroy_assembly_instructions "2413", "instructions.txt"
    @test_auth.verify
  end
  
  def test_destroy_assembly_instructions_url
    @test_auth.expect :post, @api_responses[:product_200], ['products/2413/assembly_instructions/destroy', {'url' => 'instructions.txt'}]
    resp = @ponoko.destroy_assembly_instructions_url "2413", "instructions.txt"
    @test_auth.verify
  end
  
  def test_add_hardware
    @test_auth.expect :post, @api_responses[:hardware_200],  ['products/2413/hardware', {'sku' => 'COM-00680', 'quantity' => 3}]
    sku = 'COM-00680' # LED Light Bar - White
    quantity = 3
    resp = @ponoko.post_hardware "2413", {'sku' => sku, 'quantity' => quantity}
    @test_auth.verify
  end

  def test_update_hardware
    @test_auth.expect :post, @api_responses[:hardware_200],  ['products/2413/hardware/update', {'sku' => 'COM-00680', 'quantity' => 99}]
    sku = 'COM-00680' # LED Light Bar - White
    quantity = 99
    resp = @ponoko.update_hardware "2413", {'sku' => sku, 'quantity' => quantity}
    @test_auth.verify
  end
  
  def test_destroy_hardware
    @test_auth.expect :post, @api_responses[:post_product_200],  ['products/2413/hardware/destroy', {'sku' => 'COM-00680'}]
    sku = 'COM-00680' # LED Light Bar - White
    resp = @ponoko.destroy_hardware "2413", 'sku' => sku
    @test_auth.verify
  end
  
  def test_escape_params
    @test_auth.expect :get, @api_responses[:product_200], ['products/fun%25ky[]%20key']
    resp = @ponoko.get_products "fun%ky[] key"
    product = resp['product']
    @test_auth.verify
  end
  
  def test_server_exception
    @test_auth.expect :get, @api_responses[:ponoko_exception], ['products/']

    assert_raises JSON::ParserError do
      resp = @ponoko.get_products
    end    

    @test_auth.verify
  end
  
  def test_internal_server_error
    @test_auth.expect :get, @api_responses[:ponoko_500], ['products/']

    assert_raises JSON::ParserError do
      resp = @ponoko.get_products
    end    

    @test_auth.verify
  end
  
end

