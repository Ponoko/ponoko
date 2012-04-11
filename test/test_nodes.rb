require 'test_helper'

class TestNodes < MiniTest::Unit::TestCase
  def setup
    load_test_resp

    @test_api = MiniTest::Mock.new
    Ponoko.api = @test_api
  end
  
  def test_new_node_fail
    assert Ponoko::Node.new
  end
  
  def test_get_a_list_of_nodes
    @test_api.expect(:send, 
                     make_resp(:nodes_200), 
                     ['get_nodes', nil])

    nodes = Ponoko::Node.get!

    @test_api.verify
    assert_equal 1, nodes.length
    assert_equal "Ponoko - United States", nodes.first.name
  end
  
  def test_get_a_node
    @test_api.expect(:send, 
                     make_resp(:node_200), 
                     ['get_nodes', '2413'])

    node = Ponoko::Node.get! "2413"

    @test_api.verify
    assert_equal "Ponoko - United States", node.name
  end
  
  def test_get_node_404
    @test_api.expect(:send, make_resp(:ponoko_404), ['get_nodes', 'bogus_key'])

    resp = Ponoko::Node.get! "bogus_key"

    @test_api.verify
    assert_equal Ponoko::Error, resp.class
    assert_equal 'Not Found. Unknown key', resp.message
  end
  
  def test_get_material_catalogue
    @test_api.expect(:send, 
                     make_resp(:node_200), 
                     ['get_nodes', '2413'])
    @test_api.expect(:get_material_catalogue, 
                     make_resp(:mat_cat_200),
                     ["2413"])

    node = Ponoko::Node.new "key" => "2413"

    catalogue = node.material_catalogue

    @test_api.verify
    assert_equal 2, catalogue.count
    assert_equal "Felt", catalogue.materials.first.name
  end
  
  def test_get_material_catalogue_bang
    @test_api.expect(:send, 
                     make_resp(:node_200), 
                     ['get_nodes', '2413'])
    @test_api.expect(:get_material_catalogue, 
                     make_resp(:mat_cat_200),
                     ["2413"])

    node = Ponoko::Node.new "key" => "2413"

    catalogue = node.material_catalogue!

    @test_api.verify
    assert_equal 2, catalogue.count
    assert_equal "Felt", catalogue.materials.first.name

    # Don't add the materials onto the end of the list, replace them.
    catalogue = node.material_catalogue!
    @test_api.verify
    assert_equal 2, catalogue.count

  end
  
  def test_dont_refresh_material_catalogue
    node = Ponoko::Node.new make_resp(:mat_cat_200)
    
    # Shouldn't call this method
    @test_api.expect(:get_material_catalogue, 
                     :fail,
                     ["2413"])
                     
    catalogue = node.material_catalogue # nothing raised by bad expect
  end
  
  def test_refresh_old_material_catalogue
    old_catalogue = {"key"=>"2413",
                     "materials_updated_at" => "2010/01/01 12:00:00 +0000",
                     "count"=>1,
                     "materials"=>
                      [{"updated_at"=>"2011/03/17 02:08:51 +0000",
                        "type"=>"P1",
                        "weight"=>"0.1 kg",
                        "color"=>"Fuchsia",
                        "key"=>"6812d5403269012e2f2f404062cdb04a",
                        "thickness"=>"3.0 mm",
                        "name"=>"Felt",
                        "width"=>"181.0 mm",
                        "material_type"=>"sheet",
                        "length"=>"181.0 mm",
                        "kind"=>"Fabric"},
                       ]}

    node = Ponoko::Node.new old_catalogue

    assert_equal 1, node.material_catalogue.materials.length
    @test_api.expect(:send, 
                     make_resp(:node_200), 
                     ['get_nodes', '2413'])
    @test_api.expect(:get_material_catalogue, 
                     make_resp(:mat_cat_200),
                     ["2413"])
                     
    catalogue = node.material_catalogue!

    @test_api.verify
    assert_equal 2, node.material_catalogue.materials.length
  end


  def test_dont_refresh_new_material_catalogue
    current_catalogue = {"key"=>"2413",
                         "materials_updated_at" => "2011/01/01 12:00:00 +0000",
                         "count"=>1,
                         "materials"=>
                          [{"updated_at"=>"2011/03/17 02:08:51 +0000",
                            "type"=>"P1",
                            "weight"=>"0.1 kg",
                            "color"=>"Fuchsia",
                            "key"=>"6812d5403269012e2f2f404062cdb04a",
                            "thickness"=>"3.0 mm",
                            "name"=>"Felt",
                            "width"=>"181.0 mm",
                            "material_type"=>"sheet",
                            "length"=>"181.0 mm",
                            "kind"=>"Fabric"},
                           ]}

    node = Ponoko::Node.new current_catalogue

    @test_api.expect(:send, 
                     make_resp(:node_200), 
                     ['get_nodes', '2413'])

    # Shouldn't call this method
    @test_api.expect(:get_material_catalogue, 
                     :fail,
                     ["2413"])
                     
    catalogue = node.material_catalogue! # nothing raised by bad expect
  end
  
  def test_get_material_cataloge_fail
    # Deliberately make a bad node and try to get material catalogue
    @test_api.expect(:send, make_resp(:ponoko_404), ["get_nodes", "bogus_key"])
    @test_api.expect(:get_material_catalogue, make_resp(:ponoko_404), ["bogus_key"])

    node = Ponoko::Node.new "key" => "bogus_key"

    node.material_catalogue
        
    assert_equal "Not Found. Unknown key", node.error.message
    @test_api.verify
  end

  def test_handle_unknown_field_in_class_method
    @test_api.expect(:send, 
                     make_resp(:node_unknown_field), 
                     ['get_nodes', '2413'])

    node = Ponoko::Node.get!"2413"

    @test_api.verify
    assert_equal "Ponoko - United States", node.name
  end
    
end
