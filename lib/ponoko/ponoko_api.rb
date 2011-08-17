require 'rubygems'
require 'json'
require 'net/https'
require 'uri'

require 'ponoko/ext'

module Ponoko
  class PonokoAPIError < StandardError; end
  
  class PonokoAPI
    PONOKO_API_PATH = '/services/api/v2/'

    def initialize client = nil, env = :sandbox
      @client = client.nil? ? self : client

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
      resp = @client.get "nodes/#{node_key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_material_catalogue node_key
      resp = @client.get "nodes/material-catalog/#{node_key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_orders key = nil
      resp = @client.get "orders/#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_shipping_options params
      q = params.to_query.collect do |p|
        p.collect {|k,v| "#{k}=#{v}"}
      end.flatten.join '&'

      resp = @client.get "orders/shipping_options?#{q}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def get_order_status key
      resp = @client.get "orders/status/#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def step_order key
      raise Ponoko::PonokoAPIError, "Ponoko API Sandbox only" unless @base_uri.host =~ /sandbox/

      resp = @client.get "orders/trigger-next-event/#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
        
    def post_order params
      q = params.to_query.collect do |p|
        p.collect {|k,v| "#{k}=#{v}"}
      end.flatten.join '&'

      resp = @client.post 'orders', q
      handle_error resp unless resp.code =='200'
      JSON.parse resp.body
    end

    def get_products key = nil
      resp = @client.get "products/#{key}"
      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)
    end
    
    def post_product params
#       boundary = Digest::MD5.hexdigest(Time.now.to_s)
      boundary = "arandomstringofletters"
      q = params.to_multipart.collect do |p|
        '--' + boundary + "\r\n" + p
      end.join('') + "--" + boundary + "--\r\n"

      resp = @client.post "products", q, {'Content-Type' => "multipart/form-data; boundary=#{boundary}"}

      handle_error resp unless resp.code =='200'
      JSON.parse(resp.body)      
    end
    
    def handle_error resp
      error = JSON.parse resp.body
      raise PonokoAPIError, error["error"]["message"]
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
    
    def get path
      @access.get PONOKO_API_PATH + path
    end
    
    def post path, params, headers = {}
      @access.post PONOKO_API_PATH + path, params, headers
    end
  end

end # module Ponoko

