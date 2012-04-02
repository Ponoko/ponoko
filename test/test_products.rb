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
  end

  def test_make_a_product_missing_design
    product = Ponoko::Product.new
    assert product
    
    e = assert_raises Ponoko::PonokoAPIError do
      product.send!
    end

    assert_equal "Product must have a design.", e.message
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
    assert_equal 1, product.designs.length
    assert_equal 16.02, product.designs.first.making_cost

  end
  
  def test_add_image
    product = Ponoko::Product.new 'key' => "product_key"
    image_file = File.new(File.dirname(__FILE__) + "/fixtures/3d-1_product_page.jpg")
    @test_api.expect :post_design_image, 
                      make_resp(:post_product_200), 
                      [String, {"uploaded_data" => image_file, 'default' => false}]
                      
    
    product.add_design_image! image_file

    @test_api.verify
  end
  
  def test_add_default_image
    product = Ponoko::Product.new 'key' => "product_key"
    image_file_default = File.new(File.dirname(__FILE__) + "/fixtures/lamp-1_product_page.jpg")
    @test_api.expect :post_design_image, 
                      make_resp(:post_product_200), 
                      [String, {"uploaded_data" => image_file_default, 'default' => true}]
    
    product.add_design_image! image_file_default, true

    @test_api.verify
  end
  
  def test_get_design_image
    @test_api.expect :get_design_image, 
                      @api_responses[:image_200],
                      [String, {"filename" => "3d-1_product_page.jpg"}]

    product = Ponoko::Product.new 'key' => "product_key"
    product.get_design_image_file! '3d-1_product_page.jpg'
    @test_api.verify
  end
  
  def test_add_assembly_instructions
    product = Ponoko::Product.new 'key' => "product_key"
    file = File.new(File.dirname(__FILE__) + "/fixtures/instructions.txt")
    @test_api.expect :post_assembly_instructions, 
                      make_resp(:post_product_200), 
                      [String, {"uploaded_data" => file}]
    
    product.add_assembly_instructions file

    @test_api.verify
  end
  
  def test_add_assembly_instructions_instructables
    url = 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
    @test_api.expect :post_assembly_instructions, 
                      make_resp(:post_product_200), 
                      [String, {"file_url" => url}]

    product = Ponoko::Product.new 'key' => "product_key"
    product.add_assembly_instructions url

    @test_api.verify
  end
  
  def test_get_assembly_instructions
    @test_api.expect :get_assembly_instructions, 
                      @api_responses[:assembly_200], 
                      [String, {"filename" => "instructions.txt"}]

    product = Ponoko::Product.new 'key' => "product_key"
    product.get_assembly_instructions_file! "instructions.txt"
    @test_api.verify
  end
  
  def test_add_hardware
    @test_api.expect :post_hardware, 
                      make_resp(:hardware_200), 
                      [String, {"sku" => "COM-00680", "quantity" => 3}]

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
  
  def test_server_exception
    skip "Can't test an exception at this level?"
    @test_api.expect(:send, @api_responses[:ponoko_exception], ['get_products', nil])

    assert_raises JSON::ParserError do
      Ponoko::Product.get!
    end    

    @test_auth.verify
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
