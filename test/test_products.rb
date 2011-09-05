require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class Test_Products < MiniTest::Unit::TestCase
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
    
    assert_raises Ponoko::PonokoAPIError do
      product.send!
    end
  end

  def test_make_a_product
    file = File.new(File.dirname(__FILE__) + "/Fixtures/small.svg")
    @test_api.expect :post_product, 
                      make_resp(:post_product_200), 
                      [{"ref" => "product_ref", "name"=>"Product", "description"=>"This is a product description", "designs"=>[{"uploaded_data" => file, "ref"=>"42", "material_key"=>"6bb50fd03269012e3526404062cdb04a"}]}]

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
    skip "Unfinished"
    product = Ponoko::Product.new
    image_file_default = File.new(File.dirname(__FILE__) + "/Fixtures/lamp-1_product_page.jpg")
    image_file = File.new(File.dirname(__FILE__) + "/Fixtures/3d-1_product_page.jpg")
    
    product.add_image! image_file_default, true
    product.add_image! image_file

    @test_api.verify
  end
  
  def test_add_assembly_instructions
    skip "Unfinished"
    product = Ponoko::Product.new
    product.add_assembly_instructions! file

    @test_api.verify
  end
  
  def test_add_assembly_instructions_instructables
    skip "Unfinished"
    product = Ponoko::Product.new
    product.add_assembly_instructions! file

    @test_api.verify
  end
  
  def test_add_hardware
    skip "Unfinished"
    product = Ponoko::Product.new
    product.add_hardware! sku, quantity

    @test_api.verify
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
