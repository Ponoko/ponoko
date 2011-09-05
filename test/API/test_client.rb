require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class Test_API_Nodes < MiniTest::Unit::TestCase
  def test_oauth
    skip "Un-skip this test if you have edited the OAuth code"
    ponoko = Ponoko::OAuthAPI.new env:             :production,
                                  consumer_key:    'these', 
                                  consumer_secret: 'are not',
                                  access_token:    'real', 
                                  access_secret:   'keys'

    # Just test if we can connect
    # Don't care about the response so eat the exception
    assert_raises Ponoko::PonokoAPIError do
      ponoko.get_nodes
    end
  end
      
end
