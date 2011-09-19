require 'rubygems'
require 'json'
require 'net/https'
require 'uri'

require 'ponoko/ext'

module Ponoko
  class PonokoAPIError < StandardError; end
  
  class PonokoAPI
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
    
    def get_nodes node_key = nil
      resp = @client.get "nodes/", node_key.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_material_catalogue node_key
      resp = @client.get "nodes/material-catalog/", node_key.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_orders key = nil
      resp = @client.get "orders/", key.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_shipping_options params
      resp = @client.get "orders/shipping_options?", params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_order_status key
      resp = @client.get "orders/status/", key.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def step_order key
      raise Ponoko::PonokoAPIError, "Ponoko API Sandbox only" unless @base_uri.host =~ /sandbox/

      resp = @client.get "orders/trigger-next-event/", key.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
        
    def post_order params
      resp = @client.post 'orders/', params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse resp.body
    end

    def get_products key = nil
      resp = @client.get "products/", key.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def post_product params
      boundary = "arandomstringofletters"
      query = params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post("products/", query, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"})

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def post_design product_key, params
      boundary = "arandomstringofletters"
      query = params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post("products/#{product_key}/designs", query, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"})

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def update_design product_key, params
      boundary = "arandomstringofletters"
      query = params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post("products/#{product_key}/designs/update", query, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"})

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def destroy_design product_key, design_key
      resp = @client.post "products/#{product_key.to_query}/designs/#{design_key.to_query}/destroy"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def post_design_image product_key, image_params
      # products/3c479d62f2dae6e703861e50d4271efc/design_images
      # design_images[][uploaded_data]
      # design_images[][default]
      boundary = "arandomstringofletters"
      q = image_params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post "products/#{product_key.to_query}/design_images/", q, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"}

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def get_design_image product_key, filename
      resp = @client.get "products/#{product_key.to_query}/design_images/download", filename.to_query("filename")
      handle_error resp unless resp.code =='200'
      resp.body
    end
    
    def destroy_design_image product_key, filename
      resp = @client.post "products/#{product_key.to_query}/design_images/download", filename.to_query("filename")
      handle_error resp unless resp.code =='200'
      resp.body
    end
    
    def post_assembly_instructions_file product_key, params
      boundary = "arandomstringofletters"
      q = params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post "products/#{product_key.to_query}/assembly_instructions/", q, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"}

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def post_assembly_instructions_url product_key, params
      resp = @client.post "products/#{product_key.to_query}/assembly_instructions/", params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def get_assembly_instructions key, filename
      resp = @client.get "products/#{key.to_query}/assembly_instructions/download", filename.to_query("filename")
      handle_error resp unless resp.code =='200'
      resp.body
    end
    
    def destroy_assembly_instructions_url product_key, params
      resp = @client.post "products/#{product_key.to_query}/assembly_instructions/", params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def post_hardware product_key, hardware_params
      resp = @client.post "products/#{product_key.to_query}/hardware", hardware_params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def update_hardware product_key, hardware_params
      resp = @client.post "products/#{product_key.to_query}/hardware", hardware_params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def destroy_hardware product_key, hardware_params
      resp = @client.post "products/#{product_key.to_query}/hardware", hardware_params.to_query
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def handle_error resp
      error = JSON.parse resp.body
      warn error
      error
    rescue
      raise PonokoAPIError, resp
    end

    private :handle_error
  end
    
  require 'oauth'
  
  class OAuthAPI < PonokoAPI
    def initialize params = {}
      super self, params[:env]

      consumer = OAuth::Consumer.new(params[:consumer_key], params[:consumer_secret],
                                     site:                  @base_uri,
                                     request_token_path:    "/oauth/request_token",
                                     access_token_path:     "/oauth/access_token",
                                     authorize_path:        "/oauth/authorize")
    
      access_keys = {oauth_token:           params[:access_token], 
                     oauth_token_secret:    params[:access_secret]}
    
      @access = OAuth::AccessToken.from_hash(consumer, access_keys)
    end
    
    def get path, params = nil
      @access.get PONOKO_API_PATH + path + params
    end
    
    def post path, params, headers = {}
      @access.post PONOKO_API_PATH + path, params, headers
    end
    
    def self.authorize
      print "Enter consumer key: "
      consumer_key = $stdin.gets.chomp

      print "Enter consumer secret: "
      consumer_secret = $stdin.gets.chomp
      
      
      consumer = OAuth::Consumer.new(consumer_key,          consumer_secret,
                                     site:                  'https://www.ponoko.com/',
                                     request_token_path:    "/oauth/request_token",
                                     access_token_path:     "/oauth/access_token",
                                     authorize_path:        "/oauth/authorize")
      
      

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

end # module Ponoko

