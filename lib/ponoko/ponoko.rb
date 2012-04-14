require 'net/https'
require 'uri'

require 'ponoko/ponoko_api.rb'

module Ponoko
  class << self; attr_accessor :api end

  class Sandbox
    def self.step_order order
      order.with_handle_error { Ponoko::api.step_order order.key }
    end

    def self.request_log entries
      Ponoko::api.request_log entries
    end

  end
  
  class Base
    attr_accessor :ref, :key
    attr_accessor :created_at, :updated_at
    attr_reader   :error

    def initialize params = {}
      update params
    end
    
    def update params
      params.each do |k, v|
        m = "#{k.gsub('?', '')}=".to_sym
        send(m, v) if self.respond_to? m
      end
    end

    def self.ponoko_object
      self.name.split('::').last.downcase
    end

    def self.ponoko_objects
      "#{ponoko_object}s"
    end

    def self.get! key = nil
      resp = Ponoko::api.send "get_#{ponoko_objects}", key
      
      if resp['error']
        Error.new(resp['error'])
      elsif key.nil?
        resp[ponoko_objects].collect do |p| # FIXME fetch
          new(p)
        end
      else
        new resp[ponoko_object] # FIXME fetch
      end

    rescue JSON::ParserError
      fail PonokoAPIError, "Ponoko returned an invalid response; '#{resp}'"  # FIXME resp will always be nil
    end
    
    def update!
      with_handle_error { Ponoko::api.send "get_#{self.class.ponoko_objects}", key }
    end
    
    def with_handle_error
      @error = nil;
      resp = yield
      
      if resp.is_a? Hash
        if resp['error']
          @error = Error.new(resp['error'])
        else
          data = resp[self.class.ponoko_object]
          if data.nil?
            return resp
          else
            update data
          end
        end
        self
      else
        resp
      end
      
    rescue JSON::ParserError
      fail PonokoAPIError, "Ponoko returned an invalid response; '#{resp}'"
    end
    
  end
  
  class Product < Base
    attr_accessor :name, :description, :materials_available, :node_key
    attr_reader   :designs, :design_images, :assembly_instructions, :hardware, :urls
    attr_writer   :locked, :total_make_cost

    def send!
      with_handle_error { Ponoko::api.post_product self.to_params }
    end

    def initialize params = {}
      @designs = []
      @design_images = []
      @hardware = []
      @assembly_instructions = []
      super
    end
    
    def delete!
      with_handle_error { Ponoko::api.delete_product self.key }
      nil
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
    
    def hardware= hw
      @hardware.clear
      hw.each do |h|
        @hardware << Hardware.new(h)
      end
    end
    
    def assembly_instructions= ass
      @assembly_instructions.clear
      ass.each do |a|
        @assembly_instructions << AssemblyInstruction.new(a)
      end
    end

    def design_images= di
      @design_images.clear
      di.each do |d|
        @design_images << DesignImage.new(d)
      end
    end
        
    def add_designs *designs
      designs.each do |d|
        @designs << d
      end
    end
    
    def add_design! design
      if key.nil? # product hasn't been 'saved' to Ponoko yet.
        add_designs design
      else
        with_handle_error { Ponoko::api.post_design self.key, design.to_params }
      end
    end
    
    # Adding supplementary objects to products always posts to the server
    def add_design_image! file, default = false
      if key.nil? # product hasn't been 'saved' to Ponoko yet.
        fail Ponoko::PonokoAPIError, "Design Images can only be added to Products on the server." 
      else
        with_handle_error { Ponoko::api.post_design_image self.key, {'design_images' => [{'uploaded_data' => file, 'default' => default}]} }
      end
    end
    
    def get_design_image_file! filename
      with_handle_error { Ponoko::api.get_design_image self.key, {'filename' => filename} }
    end
    
    def add_assembly_instructions! file_or_url
      if key.nil? # product hasn't been 'saved' to Ponoko yet.
        fail Ponoko::PonokoAPIError, "Assembly Instructions can only be added to Products on the server." 
      else
        if file_or_url.is_a? File
          with_handle_error { Ponoko::api.post_assembly_instructions_file self.key, {'assembly_instructions' => [{'uploaded_data' => file_or_url}]} }
        else
          with_handle_error { Ponoko::api.post_assembly_instructions_url self.key, {'assembly_instructions' => [{'file_url' => file_or_url}]} }
        end
      end
    end
    
    def get_assembly_instructions_file! filename
      with_handle_error { Ponoko::api.get_assembly_instructions self.key, {'filename' => filename} }
    end
    
    def add_hardware! hardware_or_sku, quantity = nil
      if key.nil? # product hasn't been 'saved' to Ponoko yet.
        fail Ponoko::PonokoAPIError, "Hardware can only be added to Products on the server." 
      else
        if hardware_or_sku.is_a? String # FIXME! respond_to? :to_params
          with_handle_error { Ponoko::api.post_hardware self.key, {'sku' => hardware_or_sku, 'quantity' => quantity} }
        else
          hardware_or_sku.quantity = quantity unless quatity.nil?
          with_handle_error { Ponoko::api.post_hardware self.key, hardware_or_sku.to_params }
        end
      end
    end

    def update_hardware! hardware
      if key.nil? # product hasn't been 'saved' to Ponoko yet.
        h = @hardware.detect {|h| h.sku = hardware.sku}
        h.quantity = hardware.quantity
      else
        with_handle_error { Ponoko::api.update_hardware self.key, {'sku' => hardware.sku, 'quantity' => hardware.quantity} }      
      end
    end
    
    def remove_hardware! hardware
      if key.nil? # product hasn't been 'saved' to Ponoko yet.
        @hardware.reject {|h| h.sku = hardware.sku}
      else
        with_handle_error { Ponoko::api.destroy_hardware self.key, hardware.sku }
      end
    end
    
    def to_params
      fail Ponoko::PonokoAPIError, "Product must have a Design." if @designs.empty?
      {'ref' => ref, 'name' => name, 'description' => description, 'designs' => @designs.to_params}
    end
    
    def making_cost
      @total_make_cost['making'].to_f
    end
    
    def materials_cost
      @total_make_cost['materials'].to_f
    end
    
    def total_cost
      @total_make_cost['total'].to_f
    end
    
    def currency
      @total_make_cost['currency']
    end

  end
  
  class Design < Base

    attr_accessor :material_key, :design_file, :filename, :size, :quantity, :units
    attr_accessor :content_type
    attr_reader   :material, :bounding_box, :volume

    attr_writer   :make_cost

    def add_material material
       @material = material
    end
    
    def making_cost
      @make_cost['making'].to_f
    end
    
    def material_cost
      @make_cost['material'].to_f
    end
    
    def total_cost
      @make_cost['total'].to_f
    end
    
    def currency
      @make_cost['currency']
    end

    def to_params
      fail Ponoko::PonokoAPIError, "Design must have a Design File." if design_file.nil?
      fail Ponoko::PonokoAPIError, "Design must have a Material." if material.nil?
      {'file_name' => File.basename(design_file.path), 'uploaded_data' => design_file, 'ref' => ref, 'material_key' => material.to_params}
    end   
  end
  
  class Material < Base
    attr_accessor :kind, :name, :color, :thickness, :size 
    attr_accessor :type, :length, :width, :weight, :material_type, :dimensions
    attr_accessor :updated_at
    
    def to_params
      key
    end
  end
  
  class Third_Party_Item < Base
  end
  
  class Hardware < Third_Party_Item
    attr_accessor :sku, :name, :weight, :price, :url, :quantity
    
    def to_params
      {'sku' => sku, 'quantity' => quantity}
    end
  end
  
  class DesignImage < Base
    attr_accessor :filename, :default
    
    def initialize params = {}
      @default ||= false
      super
    end
  end
  
  class AssemblyInstruction < Base
    attr_accessor :file_url, :filename
  end

  class Address < Hash; end
    
  class Order < Base
    attr_accessor :delivery_address, :events, :shipping_option_code
    attr_accessor :last_successful_callback_at, :quantity, :tracking_numbers, :currency
    attr_accessor :node_key, :products
    attr_writer   :cost, :shipped
    
    def initialize params = {}
      @events = []
      @products = []
      @delivery_address = nil
      @billing_address = nil
      super
    end
    
    def send!
      fail Ponoko::PonokoAPIError, "Order must have a Delivery Address" if delivery_address.nil?
      fail Ponoko::PonokoAPIError, "Order must have Products" if products.empty?
      fail Ponoko::PonokoAPIError, "Order must have a Shipping Option Code" if shipping_option_code.nil?
      
      with_handle_error { Ponoko::api.post_order self.to_params }
    end
    
    def add_product product, quantity = 1
      @products << {'product' => product, 'quantity' => quantity.to_s}
    end
    
    def make_cost
      @cost['making'].to_f
    end
    
    def material_cost
      @cost['materials'].to_f
    end
    
    def shipping_cost
      @cost['shipping'].to_f
    end
    
    def total_cost
      @cost['total'].to_f
    end
    
    def currency
      @cost['currency']
    end
    
    def shipped?
      @shipped
    end
    
    def status!
      with_handle_error { Ponoko::api.get_order_status key }
      if @error.nil?
        @events.last['name'] # FIXME fetch
      else
        @error
      end
    end
    
    def status
      if @events.empty?
        status!
      else
        @events.last['name'] # FIXME fetch
      end
    end
    
    def shipping_options!
      fail Ponoko::PonokoAPIError, "Order must have a Delivery Address" if delivery_address.nil?
      resp = with_handle_error { Ponoko::api.get_shipping_options self.to_params }
      resp['shipping_options']['options'] # FIXME fetch
    end
    
    def to_params
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
    
    def materials= materials
      @material_catalogue = MaterialCatalogue.new
      materials.each do |m|
        @material_catalogue.make_material m
      end
    end
    
    def material_catalogue!
      materials_date = materials_updated_at
      # update self from server to get material catalogue update time.
      update! # FIXME test for error

      if @material_catalogue.nil? or materials_updated_at > materials_date
        resp = with_handle_error { Ponoko::api.get_material_catalogue key }
        if resp.is_a?(Hash) && key == resp['key']
          update resp
        end
      end
      
      @material_catalogue
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
  
  class Error < Base
    attr_accessor :message, :errors
    
    def errors= errors
      @errors = []
      errors.each do |e|
        case e['type']
          when 'design_processing'
            @errors << DesignError.new(e)
          else
            @errors << Error.new(e)
        end
      end
    end 
  end
  
  class DesignError < Base
    attr_accessor :error_code, :name
  end
  
end # module Ponoko  
