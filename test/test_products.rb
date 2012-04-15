require 'test_helper'

class TestProducts < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_api = MiniTest::Mock.new
    Ponoko.api = @test_api
  end
  
  def test_get_products
    @test_api.expect(:send, 
                      make_resp(:products_200), 
                      ['get_products', nil])

    products = Ponoko::Product.get!

    @test_api.verify
    assert_equal 2, products.length
    assert_equal "xxx", products.first.name
  end
  

  def test_get_a_product
    @test_api.expect(:send, 
                      make_resp(:product_200), 
                      ['get_products', '8bf834a59b8f36091d86faa27c2dd4bb'])

    product = Ponoko::Product.get! "8bf834a59b8f36091d86faa27c2dd4bb"

    @test_api.verify
    assert_equal "xxx", product.name
    assert_equal "8bf834a59b8f36091d86faa27c2dd4bb", product.key
    assert_equal "product_ref", product.ref
    assert_equal 16.02, product.making_cost
    assert_equal 2.84, product.materials_cost
    assert product.materials_available?

    assert_equal 1, product.designs.length
    design = product.designs.first
    assert_equal "6bb50fd03269012e3526404062cdb04a", design.material_key
    assert_equal "bottom_new.stl", design.filename
    assert_equal 18.86, design.total_cost
    assert_equal 0, design.material_cost
    assert_equal 'USD', design.currency
  end
  
  def test_make_a_product_missing_design
    product = Ponoko::Product.new
    assert product
    
    e = assert_raises Ponoko::PonokoAPIError do
      product.send!
    end

    assert_equal "Product must have a Design.", e.message
  end
  
  def test_product_with_bad_design
    file = File.new(File.dirname(__FILE__) + "/fixtures/small.svg")
    @test_api.expect :post_product,
                      make_resp(:bad_design_400), 
                      [{"ref" => "product_ref", "name"=>"Product", "description"=>"This is a product description", "designs"=>[{"file_name" => "small.svg", "uploaded_data" => file, "ref"=>"42", "material_key"=>"6bb50fd03269012e3526404062cdb04a"}]}]

    product = Ponoko::Product.new 'ref' => 'product_ref', 'name' => 'Product', 'description' => 'This is a product description'
  
    material = Ponoko::Material.new 'key' => '6bb50fd03269012e3526404062cdb04a'
    design = Ponoko::Design.new 'ref' => '42', 'design_file' => file
    design.add_material material

    product.add_designs design

    product = product.send!

    @test_api.verify
    assert product.error
    assert_equal "Bad Request. Error processing design file(s).", product.error.message
    assert product.error.errors
    assert_equal "small.svg", product.error.errors.first.name
    assert_equal "incorrect_red", product.error.errors.first.error_code
    
  end
  
  def test_make_a_product
    file = File.new(File.dirname(__FILE__) + "/fixtures/small.svg")
    @test_api.expect :post_product, 
                      make_resp(:post_product_200), 
                      [{"ref" => "product_ref", "name"=>"Product", "description"=>"This is a product description", "designs"=>[{"file_name" => "small.svg", "uploaded_data" => file, "ref"=>"42", "material_key"=>"6bb50fd03269012e3526404062cdb04a"}]}]

    product = Ponoko::Product.new 'ref' => 'product_ref', 'name' => 'Product', 'description' => 'This is a product description'

    material = Ponoko::Material.new 'key' => '6bb50fd03269012e3526404062cdb04a'
    design = Ponoko::Design.new 'ref' => '42', 'design_file' => file
    design.add_material material

    product.add_designs design

    product.send!

    @test_api.verify

    assert_equal "product_ref", product.ref
    assert_equal "8bf834a59b8f36091d86faa27c2dd4bb", product.key
    assert_equal false, product.locked?
    assert_equal 18.86, product.total_cost
    assert_equal 'USD', product.currency
    assert_equal 1, product.designs.length
    assert_equal 16.02, product.designs.first.making_cost

  end
  
  def test_add_design
      product = Ponoko::Product.new 'ref' => 'product_ref'
      assert_equal 0, product.designs.length
      
      product.add_designs Ponoko::Design.new('ref' => '42'), Ponoko::Design.new('ref' => '43')

      assert_equal 2, product.designs.length
  end
  
  def test_add_design_bang
    product = Ponoko::Product.new 'ref' => 'product_ref'
    assert_equal 0, product.designs.length

    product.add_design! Ponoko::Design.new('ref' => '42')

    assert_equal 1, product.designs.length
  end
    
  def test_add_design_bang_to_sent_product
    product = Ponoko::Product.new 'key' => "product_key"

    assert_equal 0, product.designs.length

    file = File.new(File.dirname(__FILE__) + "/fixtures/small.svg")

    @test_api.expect :post_design, 
                      make_resp(:post_product_200), 
                      ["product_key", {"file_name"=>"small.svg", "uploaded_data"=>file, "ref"=>"42", "material_key"=>"6bb50fd03269012e3526404062cdb04a"}]
                      
    material = Ponoko::Material.new 'key' => '6bb50fd03269012e3526404062cdb04a'
    design = Ponoko::Design.new 'ref' => '42', 'design_file' => file
    design.add_material material
                          
    product.add_design! design

    @test_api.verify
    assert_equal 1, product.designs.length
  end
  
  def test_update_a_design
   assert false
  end
  
  def test_remove_a_design
   assert false
  end
  
  def test_add_image_bang
    product = Ponoko::Product.new 'key' => "product_key"
    image_file = File.new(File.dirname(__FILE__) + "/fixtures/3d-1_product_page.jpg")
    
    test_resp = make_resp(:post_product_200)
    test_resp['product'].merge!({'design_images' => [{'filename' => '3d-1_product_page.jpg', 'default' => false}]})
    @test_api.expect :post_design_image, 
                      test_resp,
                      ["product_key", {'design_images' => [{"uploaded_data" => image_file, 'default' => false}]}]
                      
    
    product.add_design_image! image_file

    @test_api.verify
    assert_equal 1, product.design_images.length
    assert_equal false, product.design_images.first.default
    assert_equal "3d-1_product_page.jpg", product.design_images.first.filename
  end
  
  def test_add_default_image_bang
    product = Ponoko::Product.new 'key' => "product_key"
    image_file_default = File.new(File.dirname(__FILE__) + "/fixtures/lamp-1_product_page.jpg")
    test_resp = make_resp(:post_product_200)
    test_resp['product'].merge!({'design_images' => [{'filename' => '3d-1_product_page.jpg', 'default' => true}]})
    @test_api.expect :post_design_image, 
                      test_resp,
                      ["product_key", {'design_images' => [{"uploaded_data" => image_file_default, 'default' => true}]}]
    
    product.add_design_image! image_file_default, true

    @test_api.verify
    assert_equal true, product.design_images.first.default
  end
  
  def test_get_design_image
    @test_api.expect :get_design_image, 
                      @api_responses[:image_200].body,
                      ["product_key", {"filename" => "3d-1_product_page.jpg"}]

    product = Ponoko::Product.new 'key' => "product_key"
    resp = product.get_design_image_file! '3d-1_product_page.jpg'

    @test_api.verify
    assert_equal "The contents of an image file", resp
  end
  
  def test_remove_design_image
   assert false
  end
  
  def test_add_assembly_instructions_file
    product = Ponoko::Product.new 'key' => "product_key"
    file = File.new(File.dirname(__FILE__) + "/fixtures/instructions.txt")

    test_resp = make_resp(:post_product_200)
    test_resp['product'].merge!({'assembly_instructions'=>[{'filename' => 'instructions.txt'}]})
    
    @test_api.expect :post_assembly_instructions_file, 
                      test_resp,
                      ["product_key", {'assembly_instructions'=>[{"uploaded_data" => file}]}]
    
    product.add_assembly_instructions! file

    @test_api.verify
    assert_equal 1, product.assembly_instructions.length
    assert_equal 'instructions.txt', product.assembly_instructions.first.filename
  end
  
  def test_add_assembly_instructions_url
    url = 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
    product = Ponoko::Product.new 'key' => "product_key"

    test_resp = make_resp(:post_product_200)
    test_resp['product'].merge!({'assembly_instructions'=>[{'file_url' => url}]})
    
    @test_api.expect :post_assembly_instructions_url, 
                      test_resp,
                      ["product_key", {'assembly_instructions'=>[{"file_url" => url}]}]

    product.add_assembly_instructions! url

    @test_api.verify
    assert_equal 1, product.assembly_instructions.length
    assert_equal "http://www.instructables.com/id/3D-print-your-minecraft-avatar/", product.assembly_instructions.first.file_url
  end
  
  def test_get_assembly_instructions
    @test_api.expect :get_assembly_instructions, 
                      @api_responses[:assembly_200].body, 
                      ["product_key", {"filename" => "instructions.txt"}]

    product = Ponoko::Product.new 'key' => "product_key"
    resp = product.get_assembly_instructions_file! "instructions.txt"

    @test_api.verify
    assert_equal "The contents of a file", resp
  end
  
  def test_remove_assembly_instructions
   assert false
  end
  
  def test_add_hardware_bang
    @test_api.expect :post_hardware, 
                      make_resp(:hardware_200), 
                      ["product_key", {"sku" => "COM-00680", "quantity" => 3}]

    product = Ponoko::Product.new 'key' => "product_key"
    sku = 'COM-00680' # LED Light Bar - White
    quantity = 3
    
    assert product.hardware.empty?
    
    product.add_hardware! sku, quantity

    @test_api.verify
    assert_equal 1, product.hardware.length
    assert_equal 'LED Light Bar - White', product.hardware.first.name
    assert_equal 3, product.hardware.first.quantity
  end
  
  def test_update_hardware
    @test_api.expect :update_hardware,
                     make_resp(:product_200),
                     ['8bf834a59b8f36091d86faa27c2dd4bb', {'sku' => 'COM-00680', 'quantity' => 99}]

    product = Ponoko::Product.new make_resp(:hardware_200)['product']

    hardware = product.hardware.first
    hardware.quantity = 99
    product.update_hardware! hardware

    @test_api.verify
    assert_equal 99, product.hardware.first.quantity
  end
  
  def test_update_hardware_unsaved_product
    product = Ponoko::Product.new make_resp(:hardware_200)['product']
    product.key = nil

    hardware = product.hardware.first

    hardware.quantity = 99
    product.update_hardware! hardware

    @test_api.verify
  end
  
  def test_remove_hardware
    @test_api.expect :destroy_hardware,
                     make_resp(:product_200),
                     ['8bf834a59b8f36091d86faa27c2dd4bb', 'COM-00680']

    product = Ponoko::Product.new make_resp(:hardware_200)['product']
    hardware = product.hardware.first
    product.remove_hardware! hardware

    @test_api.verify
    assert product.hardware.empty?
  end
  
  def test_remove_hardware_unsaved_product
    product = Ponoko::Product.new make_resp(:product_200)['product']
    product.key = nil
    hardware = product.hardware.first
    product.remove_hardware! hardware

    @test_api.verify
  end
  
  def test_delete_product
    @test_api.expect :delete_product, 
                     {"deleted"=>true, "product_key"=>"product_key"}, 
                     ['product_key']

    product = Ponoko::Product.new 'key' => "product_key"
                      
    assert_nil product.delete!
  end
  
  def test_server_exception
    skip "Can't test an exception at this level?"
    @test_api.expect(:send, @api_responses[:ponoko_exception], ['get_products', nil])

    assert_raises JSON::ParserError do
      Ponoko::Product.get!
    end    

    @test_auth.verify
  end
  
  def test_clear_old_errors
    @test_api.expect :get_assembly_instructions, 
                      make_resp(:ponoko_404), 
                      ["product_key", {"filename" => "bad-file-name.txt"}]

    product = Ponoko::Product.new 'key' => "product_key"
    assert_nil product.error
    
    product.get_assembly_instructions_file! "bad-file-name.txt"

    @test_api.verify
    assert_equal "Not Found. Unknown key", product.error.message
  
    @test_api.expect :get_assembly_instructions, 
                      @api_responses[:assembly_200].body, 
                      ["product_key", {"filename" => "good-file-name.txt"}]

    product.get_assembly_instructions_file! "good-file-name.txt"
    assert_equal nil, product.error
  
  end
end


=begin
  test "upload a product duplicate design renamed 200" do
  test "upload a product bad design file 400" do
  test "upload a product warning 200" do
  test "upload a product 2D" do
  test "upload a string instead of a file" do
  test "upload a product 3D" do
  test "upload a product material different nodes 400" do
  test "upload a product material different networks 400" do
  test "add a design" do
  test "add a design missing product 404" do
  test "remove design" do
  test "remove missing design 404" do
  test "remove design product made 400" do
  test "update design document" do
  test "update design document without file" do
  test "update missing design 404" do
  test "delete product" do
  test "update a missing product 404" do
  test "update a product" do
  test "partial update a product" do
  test "cannot update a locked product" do
  test "cannot update the design of a locked product" do

=end
