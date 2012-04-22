require 'json'
require 'net/https'
require 'uri'

require 'ponoko/ext'

module Ponoko
  class PonokoAPIError < StandardError; end
  
  class PonokoAPI
    attr_writer :base_uri
    attr :debug
    
    PONOKO_API_PATH = '/services/api/v2/'

    def initialize client, env = :sandbox
      @client = client

      @base_uri = case env
        when :test
          URI.parse 'http://localhost:3000/'
        when :sandbox
          URI.parse 'https://sandbox.ponoko.com/'
        when :production
          URI.parse 'https://www.ponoko.com/'
        end
    end
    
    def make_request
      resp = yield.tap {|resp| fail PonokoAPIError, "Ponoko returned an invalid response; #{resp.code} '#{resp.body}'" if resp.code.to_i > 499 }
      JSON.parse(resp.body)   

    rescue JSON::ParserError
      fail PonokoAPIError, "Ponoko returned an invalid response; #{resp.code} '#{resp.body}'"
    end
    
    def get_nodes node_key = nil
      make_request { @client.get "nodes/#{node_key.to_query}" }
    end
    
    def get_material_catalogue node_key
      make_request { @client.get "nodes/material-catalog/#{node_key.to_query}" }
    end
    
    def get_orders key = nil
      make_request { @client.get "orders/#{key.to_query}" }
    end
    
    def get_shipping_options params
      make_request { @client.get "orders/shipping_options?#{params.to_query}" }
    end
    
    def get_order_status key
      make_request { @client.get "orders/status/#{key.to_query}" }
    end
    
    def step_order key
      raise Ponoko::PonokoAPIError, "Ponoko API Sandbox only" unless @base_uri.host =~ /sandbox/

      make_request { @client.get "orders/trigger-next-event/#{key.to_query}" }
    end
        
    def request_log entries
      raise Ponoko::PonokoAPIError, "Ponoko API Sandbox only" unless @base_uri.host =~ /sandbox/

      make_request { @client.get "logs/requests/?#{entries.to_query('max')}" }
    end
        
    def post_order params
      make_request { @client.post "orders/", params }
    end

    def get_products key = nil
      make_request { @client.get "products/#{key.to_query}" }
    end
    
    def post_product params
      make_request { @client.post "products", params, :multipart }
    end
    
    def delete_product product_key
      make_request { @client.post "products/delete/#{product_key.to_query}", {} } # FIXME Get rid of empty argument
    end

    def post_design product_key, params
      make_request { @client.post "products/#{product_key.to_query}/add_design", params, :multipart }
    end
    
    def update_design product_key, params
      make_request { @client.post "products/#{product_key.to_query}/update_design", params, :multipart }
    end
    
    def replace_design product_key, params
      make_request { @client.post "products/#{product_key.to_query}/replace_design", params, :multipart }
    end
    
    def destroy_design product_key, design_key
      make_request { @client.post "products/#{product_key.to_query}/delete_design", design_key }
    end
    
    def post_design_image product_key, image_params
      make_request { @client.post "products/#{product_key.to_query}/design_images/", image_params, :multipart }
    end
    
    def get_design_image product_key, filename
      resp = @client.get "products/#{product_key.to_query}/design_images/download?#{filename.to_query("filename")}"
      resp.body
    end
    
    def destroy_design_image product_key, filename
      make_request { @client.post "products/#{product_key.to_query}/design_images/destroy", {"filename" => filename} }
    end
    
    def post_assembly_instructions_file product_key, params
      make_request { @client.post "products/#{product_key.to_query}/assembly_instructions/", params, :multipart }
    end
    
    def post_assembly_instructions_url product_key, params
      make_request { @client.post "products/#{product_key.to_query}/assembly_instructions/", params }
    end
    
    def get_assembly_instructions product_key, filename
      resp = @client.get "products/#{product_key.to_query}/assembly_instructions/download?#{filename.to_query("filename")}"
      resp.body
    end
    
    def destroy_assembly_instructions product_key, filename
      make_request { @client.post "products/#{product_key.to_query}/assembly_instructions/destroy", {"filename" => filename} }
    end
    
    def destroy_assembly_instructions_url product_key, url
      make_request { @client.post "products/#{product_key.to_query}/assembly_instructions/destroy", {"url" => url} }
    end
    
    def post_hardware product_key, hardware_params
      make_request { @client.post "products/#{product_key.to_query}/hardware", hardware_params }
    end
    
    def update_hardware product_key, hardware_params
      make_request { @client.post "products/#{product_key.to_query}/hardware/update", hardware_params }
    end
    
    def destroy_hardware product_key, hardware_key
      make_request { @client.post "products/#{product_key.to_query}/hardware/destroy", hardware_key }
    end
  end
    
  require 'oauth'
  
  class OAuthAPI < PonokoAPI
    def initialize params = {}
      super self, params[:env]

      consumer = OAuth::Consumer.new(params[:consumer_key], params[:consumer_secret],
                                     :site                => @base_uri,
                                     :request_token_path  => "/oauth/request_token",
                                     :access_token_path   => "/oauth/access_token",
                                     :authorize_path      => "/oauth/authorize")
    
      access_keys = {:oauth_token         => params[:access_token], 
                     :oauth_token_secret  => params[:access_secret]}
    
      @access = OAuth::AccessToken.from_hash(consumer, access_keys)
    end
    
    def get path
      @access.get PONOKO_API_PATH + path
    end
    
    def post path, params, multipart = false
      if multipart
        boundary = "~~~~~arandomstringofletters"    
        headers = {'Content-Type' => "multipart/form-data; boundary=#{boundary}"}
        
        query   = "--#{boundary}\r\n" + 
                  params.to_multipart.join('--' + boundary + "\r\n") + 
                  "--#{boundary}--\r\n"
      else
        headers = ""
        query = params
      end
            
      @access.post PONOKO_API_PATH + path, query, headers
    end
    
    def self.authorize
      print "Enter consumer key: "
      consumer_key = $stdin.gets.chomp

      print "Enter consumer secret: "
      consumer_secret = $stdin.gets.chomp

      consumer = OAuth::Consumer.new(consumer_key,          consumer_secret,
                                     :site                => 'https://www.ponoko.com/',
                                     :request_token_path  => '/oauth/request_token',
                                     :access_token_path   => '/oauth/access_token',
                                     :authorize_path      => '/oauth/authorize')
      
      

      request_token = consumer.get_request_token
      p "\nGo to this url and click 'Authorize' to get the token:"
      p request_token.authorize_url
      print "\nEnter token: "
      token = $stdin.gets.chomp
  
      access_token  = request_token.get_access_token(:oauth_verifier => token)
  
      p "\nAuthorization complete! Use the following params to access Ponoko:\n\n"
      p "consumer_key     = '#{consumer.key}'"
      p "consumer_secret  = '#{consumer.secret}'"
      p "access_token     = '#{access_token.token}'"
      p "access_secret    = '#{access_token.secret}'"
    end

  end
  
  class BasicAPI < PonokoAPI
    def initialize params = {}
      @auth_params = {'app_key' => params[:app_key], 'user_access_key' => params[:user_access_key]}
      @debug = params[:debug]
      super self, params[:env]
    end
  
    def get path
      command = PONOKO_API_PATH + path + if path.include? '?'
                  '&'
                else      
                  '?'
                end + @auth_params.to_query
      
      p command if @debug

      http = Net::HTTP.new(@base_uri.host, @base_uri.port)
      http.use_ssl = true if @base_uri.port == 443
      request = Net::HTTP::Get.new(command)
      request.basic_auth 'ponoko', 'strangeglove78'

      resp = http.request(request)

      if @debug
        p resp
        p resp.body
      end

      resp
    end

    def post path, params, multipart = false
      command = PONOKO_API_PATH + path
      p command if @debug
      p params if @debug

      http = Net::HTTP.new(@base_uri.host, @base_uri.port)
      request = Net::HTTP::Post.new(command)

      http.use_ssl = true if @base_uri.port == 443
      http.read_timeout = 3600
      http.open_timeout = 3600

      if multipart
        # FIXME split this out
        boundary = "~~~~~arandomstringofletters"
        request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"

        request.body   = "--#{boundary}\r\n" + 
                         @auth_params.merge(params).to_multipart.join('--' + boundary + "\r\n") + 
                         "--#{boundary}--\r\n"
      else
        request.body = [@auth_params.to_query, params.to_query] * '&'
      end
      
      request.basic_auth 'ponoko', 'strangeglove78'
      
      p request.body if @debug
      
      resp = http.request(request)
      
      if @debug
        p resp
        p resp.body
      end
      
      resp
    end
  end

end # module Ponoko

