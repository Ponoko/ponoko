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
      resp = @client.get "nodes/", "#{node_key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_material_catalogue node_key
      resp = @client.get "nodes/material-catalog/", "#{node_key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_orders key = nil
      resp = @client.get "orders/", "#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_shipping_options params
      q = params.to_query.collect do |p|
        p.collect {|k,v| "#{k}=#{v}"}
      end.flatten.join '&'

      resp = @client.get "orders/shipping_options?", "#{q}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_order_status key
      resp = @client.get "orders/status/", "#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def step_order key
      raise Ponoko::PonokoAPIError, "Ponoko API Sandbox only" unless @base_uri.host =~ /sandbox/

      resp = @client.get "orders/trigger-next-event/", "#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
        
    def post_order params
      q = params.to_query.collect do |p|
        p.collect {|k,v| "#{k}=#{v}"}
      end.flatten.join '&'

      resp = @client.post 'orders/', q
      handle_error resp unless resp.code =='200'
      JSON.parse resp.body
    end

    def get_products key = nil
      resp = @client.get "products/", "#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def post_product params
#       boundary = Digest::MD5.hexdigest(Time.now.to_s)
      boundary = "arandomstringofletters"
      query = params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post("products/", query, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"})

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
#     def add_image params
#       boundary = "arandomstringofletters"
#       q = params.to_multipart.collect do |p|
#         '--' + boundary + "\r\n" + p
#       end.join('') + "--" + boundary + "--\r\n"
# 
#       resp = @client.post "products/add_image", q, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"}
# 
#       handle_error resp unless resp.code =='200'
#       JSON.parse(resp.body)      
#     end
#     
#     def add_assembly_instructions params
#       boundary = "arandomstringofletters"
#       q = params.to_multipart.collect do |p|
#         '--' + boundary + "\r\n" + p
#       end.join('') + "--" + boundary + "--\r\n"
# 
#       resp = @client.post "products/add_assembly", q, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"}
# 
#       handle_error resp unless resp.code =='200'
#       JSON.parse(resp.body)      
#     end
#     
#     def add_hardware params
#       q = params.to_query.collect do |p|
#         p.collect {|k,v| "#{k}=#{v}"}
#       end.flatten.join '&'
# 
#       resp = @client.post "products/add_hardware", q
# 
#       handle_error resp unless resp.code =='200'
#       JSON.parse(resp.body)      
#     end
#     
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
      @access.get PONOKO_API_PATH + path + CGI.escape(params)
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

