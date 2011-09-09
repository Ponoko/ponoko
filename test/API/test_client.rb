require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class Test_Client < MiniTest::Unit::TestCase
  def test_oauth
    skip "Un-skip this test if you have edited the OAuth code"
    ponoko = Ponoko::OAuthAPI.new env:             :production,
                                  consumer_key:    'these', 
                                  consumer_secret: 'are not',
                                  access_token:    'real', 
                                  access_secret:   'keys'

    # Just test if we can connect
    ponoko.get_nodes
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
    p resp
  end
  
end
