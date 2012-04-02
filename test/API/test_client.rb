require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class TestClient < MiniTest::Unit::TestCase
  def test_oauth
    skip "Un-skip this test if you have edited the OAuth code"
    ponoko = Ponoko::OAuthAPI.new env:             :production,
                                  consumer_key:    'these', 
                                  consumer_secret: 'are not',
                                  access_token:    'real', 
                                  access_secret:   'keys'

    # Just test if we can connect
    ponoko.get_nodes

    ponoko.post_product

  end
  
  def test_error_handling
#     error = jj {"error"=>{"message"=>"Not Found. Unknown key", "request"=>{"key"=>"bogus_key"}}}
#   
#     out = Ponoko::handle_error error
#     assert out == error
#     
#     error = Net::HTTP::Exception.new
#     out = Ponoko::handle_error error
#     assert out == error
  end
      
  def test_escape_params
    skip "Un-skip this test if you have edited the OAuth code"
    ponoko = Ponoko::OAuthAPI.new env:             :production,
                                  consumer_key:    'these', 
                                  consumer_secret: 'are not',
                                  access_token:    'real', 
                                  access_secret:   'keys'


    resp = ponoko.get_products "fun/ky[] key"
    assert resp
  end
  
  def test_simple_auth
    skip "Un-skip this test if you have edited the Simple Auth code"
    ponoko = Ponoko::BasicAPI.new env:             :production,
                                  app_key:         'not an app', 
                                  user_access_key: 'not a user'

    # Just test that the call makes it to Ponoko. Don't care about the result
    assert ponoko.get_products("fun/ky[] key"), "Just test that the call makes it to Ponoko. Don't care about the result"

    p ponoko.post_product('key' => "fun/ky[] key")#, "Just test that the call makes it to Ponoko. Don't care about the result"
  end
  
end
