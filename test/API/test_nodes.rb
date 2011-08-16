require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class Test_Client < MiniTest::Unit::TestCase
  def setup
    load_test_resp
    
    @test_auth = MiniTest::Mock.new
    @ponoko = Ponoko::PonokoAPI.new @test_auth

  end

  def test_api_get_node_list
    @test_auth.expect(:get, @api_responses[:nodes_200], ['nodes/'])

    resp = @ponoko.get_nodes
    
    @test_auth.verify
    assert_equal 1, resp['nodes'].length
    assert_equal "Ponoko - United States", resp['nodes'].first['name']
  end
  
  def test_api_get_node_404
    @test_auth.expect(:get, @api_responses[:ponoko_404], ['nodes/bogus_key'])

    assert_raises Ponoko::PonokoAPIError do
      @ponoko.get_nodes "bogus_key"
    end    

    @test_auth.verify
  end
  
  def test_api_get_node
    @test_auth.expect(:get, @api_responses[:node_200], ['nodes/2413'])

    resp = @ponoko.get_nodes "2413"

    @test_auth.verify
    assert_equal '2413', resp['node']['key']
    assert_equal "Ponoko - United States", resp['node']['name']
  end
  
  def test_api_get_material_cataloge_fail
    @test_auth.expect(:get, @api_responses[:ponoko_404], ["nodes/material-catalog/bogus_key"])

    assert_raises Ponoko::PonokoAPIError do
      @ponoko.get_material_catalogue 'bogus_key'
    end
    
    @test_auth.verify
  end
  
  def test_api_get_material_cataloge
    @test_auth.expect(:get, @api_responses[:mat_cat_200], ["nodes/material-catalog/2413"])

    materials = @ponoko.get_material_catalogue '2413'

    @test_auth.verify
    
    assert_equal '2413', materials['key']
    assert_equal 347, materials['count']
    assert_equal 2, materials['materials'].length
    assert_equal "Felt", materials['materials'].first['name']
  end
    
end
