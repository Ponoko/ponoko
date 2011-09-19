require 'net/https'
require 'uri'

require 'ponoko/ponoko_api.rb'

module Ponoko
  def self.api= a
    @api = a
  end
  
  def self.api
    @api
  end
  
  class Sandbox
    def self.step_order order
      resp = Ponoko::api.step_order order.key
      order.update resp['order']
    end
  end

  class Base
    attr_accessor :ref, :key
    attr_accessor :created_at, :updated_at

    def initialize params = {}
      update params
    end
    
    def update params
      params.each do |k,v|
        send("#{k.gsub('?', '')}=", v)
      end
    end

    def self.ponoko_object
      self.name.split('::').last.downcase
    end

    def self.ponoko_objects
      "#{ponoko_object}s"
    end

    def self.get! key = nil
#       resp = with_handle_error { Ponoko::api.send "get_#{ponoko_objects}", key }
      resp = Ponoko::api.send "get_#{ponoko_objects}", key
      if key.nil?
        resp[ponoko_objects].collect do |p|
          new(p)
        end
      else
        new resp[ponoko_object]
      end
    end
    
    def update!
      resp = Ponoko::api.send "get_#{self.class.ponoko_objects}", key
      update resp[self.class.ponoko_object]
    end
    
      def with_handle_error
        resp = JSON.parse yield
      rescue
        raise    
      else
        if resp['error']
          fail PonokoAPIError, resp['message']
        end
        resp
      end
    
#     protected :with_handle_error
        
  end
  
  class Product < Base
    attr_accessor :name, :description, :materials_available, :locked, :total_make_cost, 
                  :node_key, :hardware
    attr_reader   :designs, :design_images, :hardware, :assembly_instructions
    
    private :total_make_cost, :locked
    
    def send!
      raise Ponoko::PonokoAPIError, "Product must have a design." if designs.empty?
      resp = Ponoko::api.post_product self.to_params
      update resp['product']
      self
    end

    def initialize params = {}
      @designs = []
      @design_images = []
      @hardware = []
      @assembly_instructions = []
      super params
    end
    
    def locked?
      @locked
    end
    
    def materials_available?
      @materials_available
    end    

    def designs= designs
      @designs.clear
      designs.each do |d|
        add_designs Design.new(d)
      end
    end
    
    private :designs=
    
    def hardware= hw
      @hardware.clear
      hw.each do |h|
        add_hardware Hardware.new(h), 1
      end
    end
    
    private :hardware=
    
    def add_designs *designs # quantity?
      designs.each do |d|
        @designs << d
      end
    end
    
    def add_design!
      resp = Ponoko::api.post_design self.key, design
      update resp['product']
    end
    
    def add_design_image file, default = false
      resp = Ponoko::api.post_design_image self.key, {'uploaded_data' => file, 'default' => default}
      update resp['product']
    end
    
    def add_design_image! file, default = false
      resp = Ponoko::api.post_design_image self.key, {'uploaded_data' => file, 'default' => default}
      update resp['product']
    end
    
    def get_design_image_file! filename
      Ponoko::api.get_design_image self.key, {'filename' => filename}
    end
    
    def add_assembly_instructions file_or_url
      resp = if file_or_url.is_a? File
        Ponoko::api.post_assembly_instructions self.key, {'uploaded_data' => file_or_url}
      else
        Ponoko::api.post_assembly_instructions self.key, {'file_url' => file_or_url}
      end
          
      update resp['product']
    end
    
    def add_assembly_instructions! file_or_url
      resp = Ponoko::api.post_assembly_instructions self.key, {'uploaded_data' => file_or_url}
      update resp['product']
    end
    
    def get_assembly_instructions_file! filename
      Ponoko::api.get_assembly_instructions self.key, {'filename' => filename}
    end
    
    def add_hardware hardware_or_sku, quantity
      if hardware_or_sku.is_a? String
        resp = Ponoko::api.post_hardware self.key, {'sku' => sku, 'quantity' => quantity}
        update resp['product']
      else
        hardware << hardware_or_sku
      end
      
      self
    end

    def add_hardware! sku, quantity
      resp = Ponoko::api.post_hardware self.key, {'sku' => sku, 'quantity' => quantity}
      update resp['product']
    end

    def to_params
      raise Ponoko::PonokoAPIError, "Product must have a Design." if designs.empty?
      {'ref' => ref, 'name' => name, 'description' => description, 'designs' => @designs.to_params}
    end
    
    def making_cost
      total_make_cost['making'].to_f
    end
    
    def materials_cost
      total_make_cost['materials'].to_f
    end
    
    def total_cost
      total_make_cost['total'].to_f
    end
    
  end
  
  class Design < Base
    attr_accessor :make_cost, :material_key, :design_file, :filename, :size, :quantity
    attr_accessor :content_type
    attr_reader   :material

    private :make_cost
  
    def add_material material
       @material = material
    end
    
    def making_cost
      make_cost['making'].to_f
    end
    
    def material_cost
      make_cost['material'].to_f
    end
    
    def total_cost
      make_cost['total'].to_f
    end
    
    def to_params
      raise Ponoko::PonokoAPIError, "Design must have a Material." if material.nil?
      {'uploaded_data' => design_file, 'ref' => ref, 'material_key' => material.to_params}
    end   
  end
  
  class Material < Base
    attr_accessor :type, :weight, :color, :thickness, :name, :width, :material_type
    attr_accessor :length, :kind
    attr_accessor :updated_at
    
    def to_params
      key
    end
  end
  
  class Third_Party_Item < Base
  end
  
  class Hardware < Third_Party_Item
    attr_accessor :sku, :name, :weight, :price, :url, :quantity
  end
  
  class Address < Hash; end
    
  class Order < Base
    attr_accessor :shipped, :delivery_address, :events, :shipping_option_code
    attr_accessor :last_successful_callback_at, :quantity, :tracking_numbers, :currency
    attr_accessor :node_key, :cost
    attr_accessor :products
    
    private :cost, :shipped
    
    def initialize params = {}
      @events = []
      @products = []
      @delivery_address = nil
      @billing_address = nil
      super
    end
    
    def send!
      raise Ponoko::PonokoAPIError, "Order must have a Shipping Option Code" if shipping_option_code.nil?
      raise Ponoko::PonokoAPIError, "Order must have Products" if products.empty?

      resp = Ponoko::api.post_order self.to_params
      update resp['order']
      self
    end
    
    def add_product product, quantity = 1
      @products << {'product' => product, 'quantity' => quantity.to_s}
    end
    
    def make_cost
      cost['making'].to_f
    end
    
    def material_cost
      cost['materials'].to_f
    end
    
    def shipping_cost
      cost['shipping'].to_f
    end
    
    def total_cost
      cost['total'].to_f
    end
    
    def shipped?
      @shipped
    end
    
    def status!
      resp = Ponoko::api.get_order_status key
      update resp['order']
      status
    end
    
    def status
      status! if @events.empty?
      @events.last['name']
    end
    
    def shipping_options!
      resp = Ponoko::api.get_shipping_options self.to_params
      resp['shipping_options']['options']
    end
    
    def to_params
      raise Ponoko::PonokoAPIError, "Order must have a Delivery Address" if delivery_address.nil?
      raise Ponoko::PonokoAPIError, "Order must have Products" if products.empty?
      
      params = {}
      products = @products.collect do |p|
        {'key' => p['product'].key, 'quantity' => p['quantity']}
      end
      
      params['ref'] = ref
      params['products'] = products
      params['shipping_option_code'] = shipping_option_code unless shipping_option_code.nil?
      params['delivery_address'] = delivery_address.to_params
      
      params
    end
  end
  
  class Node < Base
    attr_accessor :name, :materials_updated_at, :count, :last_updated
    
    def initialize params = {}
      super
    end
    
    def materials= materials
      @material_catalogue = MaterialCatalogue.new
      materials.each do |m|
        @material_catalogue.make_material m
      end
    end
    
    private :materials=
    
    def material_catalogue!
      materials_date = materials_updated_at
      update! # update self from server

      if @material_catalogue.nil? or materials_updated_at > materials_date
        resp = Ponoko::api.get_material_catalogue key
        raise Ponoko::PonokoAPIError, "Unknown Error Occurred" unless key ==  resp['key']
        update resp
      end
      
      material_catalogue
    end

    def material_catalogue
      material_catalogue! if @material_catalogue.nil?
      @material_catalogue
    end
  end
  
  class MaterialCatalogue
    attr_reader :materials

    def initialize
      @materials = []
      @catalogue = Hash.new{|h,k| h[k] = Hash.new(&h.default_proc) }
    end

    def make_material material
      m = Material.new(material)
      @materials << m
      @catalogue[m.kind][m.name][m.color][m.thickness][m.type] = m
    end
    
    def [] key
      @catalogue[key]
    end
    
    def count
      @materials.length
    end
  end
  
end # module Ponoko  
  
