begin 
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  p "gem install simplecov for code coverage"
end

require 'minitest/unit'
require 'minitest/autorun'

require 'ponoko'

FakeHTTPResponse = Struct.new(:code, :body)

class MiniTest::Unit::TestCase
  def load_test_resp
    @api_responses = {
      :ponoko_404   => FakeHTTPResponse.new('404', "{\"error\":{\"message\":\"Not Found. Unknown key\",\"request\":{\"key\":\"bogus_key\"}}}"),

      :nodes_200          => FakeHTTPResponse.new('200', "{\"nodes\": [{\"key\": \"2413\", \"name\": \"Ponoko - United States\", \"materials_updated_at\": \"2011/01/01 12:00:00 +0000\"}]}"),
      :node_200           => FakeHTTPResponse.new('200', "{\"node\": {\"key\": \"2413\", \"name\": \"Ponoko - United States\", \"materials_updated_at\": \"2011/01/01 12:00:00 +0000\"}}"),
      :node_unknown_field => FakeHTTPResponse.new('200', "{\"node\": {\"unknown_field\": \"Unknown field value\", \"key\": \"2413\", \"name\": \"Ponoko - United States\", \"materials_updated_at\": \"2011/01/01 12:00:00 +0000\"}}"),

      :mat_cat_200  => FakeHTTPResponse.new('200', "{\"key\":\"2413\",\"count\":347,\"materials\":[{\"updated_at\":\"2011/03/17 02:08:51 +0000\",\"type\":\"P1\",\"weight\":\"0.1 kg\",\"color\":\"Fuchsia\",\"key\":\"6812d5403269012e2f2f404062cdb04a\",\"thickness\":\"3.0 mm\",\"name\":\"Felt\",\"width\":\"181.0 mm\",\"material_type\":\"sheet\",\"length\":\"181.0 mm\",\"kind\":\"Fabric\"},
                                                                                                   {\"updated_at\":\"2011/03/17 02:08:51 +0000\",\"type\":\"P2\",\"weight\":\"0.3 kg\",\"color\":\"Fuchsia\",\"key\":\"68140dc03269012e2f31404062cdb04a\",\"thickness\":\"3.0 mm\",\"name\":\"Felt\",\"width\":\"384.0 mm\",\"material_type\":\"sheet\",\"length\":\"384.0 mm\",\"kind\":\"Fabric\"}]}"),

      :products_200 => FakeHTTPResponse.new('200', "{\"products\":[{\"name\":\"xxx\",\"created_at\":\"2011/07/19 09:14:45 +0000\",\"updated_at\":\"2011/07/19 09:14:47 +0000\",\"ref\":null,\"key\":\"8bf834a59b8f36091d86faa27c2dd4bb\"},{\"name\":\"xxx\",\"created_at\":\"2011/07/19 09:13:51 +0000\",\"updated_at\":\"2011/07/19 09:13:53 +0000\",\"ref\":null,\"key\":\"b1129260f306179486935bd63f26a7a3\"}]}"),
      :product_200  => FakeHTTPResponse.new('200', "{\"product\":{\"name\":\"xxx\",
                                                                  \"created_at\":\"2011/07/19 09:14:45 +0000\",
                                                                  \"updated_at\":\"2011/07/19 09:14:47 +0000\",
                                                                  \"locked?\":false,
                                                                  \"total_make_cost\":{\"total\":\"18.86\",
                                                                                       \"making\":\"16.02\",
                                                                                       \"materials\":\"2.84\",
                                                                                       \"currency\":\"USD\"},
                                                                  \"node_key\":\"2e9d8c90326e012e359f404062cdb04a\",
                                                                  \"ref\":\"product_ref\",
                                                                  \"description\":null,
                                                                  \"key\":\"8bf834a59b8f36091d86faa27c2dd4bb\",
                                                                  \"materials_available?\":true,
                                                                  \"designs\":[{\"size\":137984,
                                                                                \"created_at\":\"2011/07/19 09:14:45 +0000\",
                                                                                \"quantity\":1,
                                                                                \"content_type\":\"application/stl\",
                                                                                \"updated_at\":\"2011/07/19 09:14:49 +0000\",
                                                                                \"material_key\":\"6bb50fd03269012e3526404062cdb04a\",
                                                                                \"filename\":\"bottom_new.stl\",
                                                                                \"ref\":\"42\",
                                                                                \"key\":\"b417306bffdfe15b4500a6372305ba10\",
                                                                                \"make_cost\":{\"total\":\"18.86\",
                                                                                               \"making\":\"16.02\",
                                                                                               \"materials\":\"2.84\",
                                                                                               \"currency\":\"USD\"}}]}}"),

      :product_missing_design_400 => FakeHTTPResponse.new('400', "{\"error\":{\"message\":\"Bad Request. Product must have a design.\",\"request\":{\"key\":null}}}"),
      :bad_design_400             => FakeHTTPResponse.new('400', "{\"error\":{\"errors\":[{\"error_code\":\"incorrect_red\",
                                                                                           \"type\":\"design_processing\",
                                                                                           \"name\":\"small.svg\"}],
                                                                                           \"message\":\"Bad Request. Error processing design file(s).\"},
                                                                               \"message\":\"Bad Request. Error processing design file(s).\"}"),

      :post_product_200 => FakeHTTPResponse.new('200', "{\"product\":{\"name\":\"Product\",
                                                                      \"created_at\":\"2011/07/19 09:14:45 +0000\",
                                                                      \"updated_at\":\"2011/07/19 09:14:47 +0000\",
                                                                      \"locked?\":false,
                                                                      \"total_make_cost\":{\"total\":\"18.86\",
                                                                                           \"making\":\"16.02\",
                                                                                           \"materials\":\"2.84\",
                                                                                           \"currency\":\"USD\"},
                                                                      \"node_key\":\"2e9d8c90326e012e359f404062cdb04a\",
                                                                      \"ref\":\"product_ref\",
                                                                      \"description\":\"This is a product description\",
                                                                      \"key\":\"8bf834a59b8f36091d86faa27c2dd4bb\",
                                                                      \"materials_available?\":true,
                                                                      \"designs\":[{\"size\":137984,
                                                                                    \"created_at\":\"2011/07/19 09:14:45 +0000\",
                                                                                    \"quantity\":1,
                                                                                    \"content_type\":\"application/stl\",
                                                                                    \"updated_at\":\"2011/07/19 09:14:49 +0000\",
                                                                                    \"material_key\":\"6bb50fd03269012e3526404062cdb04a\",
                                                                                    \"filename\":\"small.svg\",
                                                                                    \"ref\":\"42\",
                                                                                    \"key\":\"b417306bffdfe15b4500a6372305ba10\",
                                                                                    \"make_cost\":{\"total\":\"18.86\",
                                                                                                   \"making\":\"16.02\",
                                                                                                   \"materials\":\"2.84\",
                                                                                                   \"currency\":\"USD\"}}]}}"),
      
      :orders_200   => FakeHTTPResponse.new('200', "{\"orders\": [{\"key\": \"order_key\", \"ref\": \"4321\", \"shipped\": \"true\", \"created_at\": \"2011/01/01 12:00:00 +0000\", \"updated_at\": \"2011/01/01 12:00:00 +0000\"}]}"),
      :order_200    => FakeHTTPResponse.new('200', "{\"order\": {\"key\": \"order_key\", \"ref\": \"4321\", \"products\":[{\"key\": \"1234\", \"ref\": \"4321\", \"quantity\": 1}], \"node_key\": \"1234\", \"shipped\": false, \"created_at\": \"2011/01/01 12:00:00 +0000\", \"updated_at\": \"2011/01/01 12:00:00 +0000\", \"cost\": {\"currency\": \"USD\", \"making\": \"56.78\", \"materials\": \"56.78\", \"shipping\": \"56.78\", \"total\": \"56.78\"}, \"shipping_option_code\": \"ups_ground\", \"tracking_numbers\": [\"xxx-yyy\"], \"events\": [{\"name\": \"design_checked\", \"completed_at\": \"2011/01/01 12:00:00 +0000\"}]}}"),
      :bump_order   => FakeHTTPResponse.new('200', "{\"order\": {\"key\": \"order_key\", \"ref\": \"4321\", \"shipped\": false, \"events\": [{\"name\": \"design_checked\", \"completed_at\": \"2011/01/01 12:00:00 +0000\"}]}}"),
      :make_200     => FakeHTTPResponse.new('200', "{\"order\": {\"key\": \"order_key\", \"ref\": \"order_ref\", \"products\": [{\"key\": \"1234\", \"ref\": \"4321\", \"quantity\": 1}], \"node_key\": \"1234\", \"shipped\": false, \"created_at\": \"2011/01/01 12:00:00 +0000\", \"updated_at\": \"2011/01/01 12:00:00 +0000\", \"cost\": {\"currency\": \"USD\", \"making\": \"56.78\", \"materials\": \"56.78\", \"shipping\": \"56.78\", \"total\": \"56.78\"}, \"shipping_option_code\": \"ups_ground\", \"tracking_numbers\": [\"xxx-yyy\"], \"events\": [{\"name\": \"design_checked\", \"completed_at\": \"2011/01/01 12:00:00 +0000\"}]}}"),
      :status       => FakeHTTPResponse.new('200', "{\"order\": {\"key\": \"order_key\", \"ref\": \"4321\", \"shipped\": false, \"events\": [{\"name\": \"design_checked\", \"completed_at\": \"2011/01/01 12:00:00 +0000\"}], \"last_successful_callback_at\": \"2011/01/01 12:00:00 +0000\", \"shipping_option_code\": \"ups_ground\", \"tracking_numbers\": [\"xxx-yyy\"]}}"),

      :shipping_200 => FakeHTTPResponse.new('200', "{\"shipping_options\": {\"products\": [{\"key\": \"1234\", \"ref\": \"4321\", \"quantity\": 1},{\"key\": \"1235\", \"ref\": \"abcdef\", \"quantity\": 99}], \"quantity\": 1, \"currency\": \"USD\", \"options\": [{\"code\": \"ups_ground\", \"name\": \"UPS Ground\", \"price\": \"56.78\"}]}}"),
      :image_200    => FakeHTTPResponse.new('200', "The contents of an image file"),
      :assembly_200 => FakeHTTPResponse.new('200', "The contents of a file"),
      :hardware_200 => FakeHTTPResponse.new('200', "{\"product\":{\"name\":\"xxx\",
                                                                  \"created_at\":\"2011/07/19 09:14:45 +0000\",
                                                                  \"updated_at\":\"2011/07/19 09:14:47 +0000\",
                                                                  \"locked?\":false,
                                                                  \"total_make_cost\":{\"total\":\"18.86\",
                                                                                       \"making\":\"16.02\",
                                                                                       \"materials\":\"2.84\",
                                                                                       \"currency\":\"USD\"},
                                                                  \"node_key\":\"2e9d8c90326e012e359f404062cdb04a\",
                                                                  \"ref\":\"product_ref\",
                                                                  \"description\":null,
                                                                  \"key\":\"8bf834a59b8f36091d86faa27c2dd4bb\",
                                                                  \"hardware\":[{\"sku\":\"COM-00680\",
                                                                                 \"name\":\"LED Light Bar - White\",
                                                                                 \"weight\":\"9.9kg\",
                                                                                 \"price\":\"9.99\",
                                                                                 \"quantity\":3
                                                                                 }],
                                                                  \"materials_available?\":true,
                                                                  \"designs\":[{\"size\":137984,
                                                                                \"created_at\":\"2011/07/19 09:14:45 +0000\",
                                                                                \"quantity\":1,
                                                                                \"content_type\":\"application/stl\",
                                                                                \"updated_at\":\"2011/07/19 09:14:49 +0000\",
                                                                                \"material_key\":\"6bb50fd03269012e3526404062cdb04a\",
                                                                                \"filename\":\"bottom_new.stl\",
                                                                                \"ref\":\"42\",
                                                                                \"key\":\"b417306bffdfe15b4500a6372305ba10\",
                                                                                \"make_cost\":{\"total\":\"18.86\",
                                                                                               \"making\":\"16.02\",
                                                                                               \"materials\":\"2.84\",
                                                                                               \"currency\":\"USD\"}}]}}"),

      :ponoko_exception   => FakeHTTPResponse.new('500', "<html>Exceptions return HTML</html>")
    }
  end
  
  def make_resp key
    load_test_resp if @api_responses.nil?
    JSON.parse @api_responses[key].body
  end
  
end

