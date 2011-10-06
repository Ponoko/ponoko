require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class TestExt < MiniTest::Unit::TestCase
  def test_string_to_query
    assert_equal "A%20test%20string",                "A test string".to_query
    assert_equal "A%20test%20key=A%20test%20string", "A test string".to_query("A test key")
  end
  
  def test_array_to_query
    a = ["A test key", "A test string"]
    assert_equal "A%20test[]=A%20test%20key&A%20test[]=A%20test%20string", a.to_query("A test")  
  
  end
  
  def test_hash_to_query
    h = {"First key" => "A test string", "Second key" => 99}
    assert_equal "First%20key=A%20test%20string&Second%20key=99", h.to_query
    assert_equal "A%20test[First%20key]=A%20test%20string&A%20test[Second%20key]=99", h.to_query("A test")

    # With a Fixnum
    h = {"A test key" => 99}
    assert_equal "A%20test%20key=99", h.to_query

    # With a Float
    h = {"A test key" => 9.9}
    assert_equal "A%20test%20key=9.9", h.to_query
  end
  
  def test_string_to_multipart
    assert_equal "Content-Disposition: form-data; name=\"A test key\"\r\n\r\nA test string\r\n", "A test string".to_multipart("A test key")
  end
  
  def test_array_to_multipart
    a = ["A test key", "A test string"]
    assert_equal ["Content-Disposition: form-data; name=\"A test[]\"\r\n\r\nA test key\r\n",
                  "Content-Disposition: form-data; name=\"A test[]\"\r\n\r\nA test string\r\n"], a.to_multipart("A test")
  end

  def test_hash_to_multipart
    h = {"A test key" => "A test string"}
    assert_equal ["Content-Disposition: form-data; name=\"A test key\"\r\n\r\nA test string\r\n"], h.to_multipart

    assert_equal ["Content-Disposition: form-data; name=\"A test[A test key]\"\r\n\r\nA test string\r\n"], h.to_multipart("A test")
  end

end