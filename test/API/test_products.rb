require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class Test_API_Products < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_auth = MiniTest::Mock.new
    @ponoko = Ponoko::PonokoAPI.new @test_auth

  end

  def test_api_get_product_list
    @test_auth.expect(:get, @api_responses[:products_200], ['products/', nil])

    resp = @ponoko.get_products
    
    products = resp['products']

    @test_auth.verify
    assert_equal 2, products.length
    assert_equal "xxx", products.first['name']
  end
  
  def test_api_get_product_404
    @test_auth.expect(:get, @api_responses[:ponoko_404], ['products/', 'bogus_key'])

    resp = @ponoko.get_products "bogus_key"

    assert_equal 'error', resp.keys.first
    @test_auth.verify
  end
  
  def test_api_get_product
    @test_auth.expect(:get, @api_responses[:product_200], ['products/', '2413'])

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
    @test_auth.expect :post, @api_responses[:product_missing_design_400], ["products/", "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    resp = @ponoko.post_product({:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref'})

    assert_equal 'error', resp.keys.first
    @test_auth.verify
  end

  def test_api_make_a_product
    @test_auth.expect :post, @api_responses[:post_product_200], ["products/", "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[][uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[][ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[][material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]
    
    file = File.new(File.dirname(__FILE__) + "/../fixtures/small.svg")
    resp = @ponoko.post_product({:name => 'Product', :notes => 'This is a product description', :ref => 'product_ref',
                                :designs => [{:uploaded_data => file, :ref => '42', :material_key => '6bb50fd03269012e3526404062cdb04a'}]})

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
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/add_design_images', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    image_file_default = File.new(File.dirname(__FILE__) + "/../fixtures/lamp-1_product_page.jpg")
    image_file = File.new(File.dirname(__FILE__) + "/../fixtures/3d-1_product_page.jpg")

    resp = @ponoko.add_design_image "2413", {:uploaded_data => image_file_default, :default => true}
    resp = @ponoko.add_design_image "2413", {:uploaded_data => image_file}
  end
  
  def test_get_an_image
    @test_auth.expect(:get, @api_responses[:image_200], ['products/2413/design_images/download','filename=lamp-1_product_page.jpg'])

    resp = @ponoko.get_design_image "2413", "lamp-1_product_page.jpg"

    @test_auth.verify
    assert_equal "The contents of an image file", resp
  end
  
  def test_add_assembly_instructions
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/add_assembly_instructions', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    file = File.new(File.dirname(__FILE__) + "/../fixtures/instructions.txt")
    resp = @ponoko.add_assembly_instructions "2413", :uploaded_data => file

    assert resp
    @test_auth.verify
  end
  
  def test_add_assembly_instructions_instructables
    @test_auth.expect :post, @api_responses[:post_product_200], ['products/add_assembly_instructions', "--arandomstringofletters\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nProduct\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"notes\"\r\n\r\nThis is a product description\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"ref\"\r\n\r\nproduct_ref\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[uploaded_data]\"; filename=\"small.svg\"\r\nContent-Transfer-Encoding: binary\r\nContent-Type: application/.svg\r\n\r\nthis is a small file\n\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[ref]\"\r\n\r\n42\r\n--arandomstringofletters\r\nContent-Disposition: form-data; name=\"designs[material_key]\"\r\n\r\n6bb50fd03269012e3526404062cdb04a\r\n--arandomstringofletters--\r\n", {"Content-Type"=>"multipart/form-data; boundary=arandomstringofletters"}]

    url = 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
    resp = @ponoko.add_assembly_instructions '2413', :file_url => url

    assert resp
    @test_auth.verify
  end
  
  def test_get_assembly_instructions
    @test_auth.expect(:get, @api_responses[:assembly_200], ['products/2413/assembly_instructions/download','filename=instructions.txt'])

    resp = @ponoko.get_assembly_instructions "2413", "instructions.txt"

    @test_auth.verify
    assert_equal "The contents of a file", resp
  end
  
  def test_add_hardware
    @test_auth.expect :post, @api_responses[:post_product_200],  ['products/2413/hardware','sku=COM-00680&quantity=3']
    sku = 'COM-00680' # LED Light Bar - White
    quantity = 3

    resp = @ponoko.add_hardware "2413", {:sku => sku, :quantity => quantity}

    @test_auth.verify
  end
  
  def test_escape_params
    @test_auth.expect(:get, @api_responses[:product_200], ['products/', 'funky[] key'])

    resp = @ponoko.get_products({:key => "funky[] key"})

    product = resp['product']

    @test_auth.verify
  end
  
end

