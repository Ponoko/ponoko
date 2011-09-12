require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class TestExt < MiniTest::Unit::TestCase
  def test_string_to_query
    k = "A test key"
    s = "A test string"
    
    assert_equal "A%20test%20string", s.to_query
    assert_equal "A%20test%20key=A%20test%20string", s.to_query(k)
  end
  
  def test_hash__to_query
    h = {"A test key" => "A test string"}
    assert_equal "A%20test%20key=A%20test%20string", h.to_query

    # With a Fixnum
    h = {"A test key" => 99}
    assert_equal "A%20test%20key=99", h.to_query

    # With a Float
    h = {"A test key" => 9.9}
    assert_equal "A%20test%20key=9.9", h.to_query
  end

end