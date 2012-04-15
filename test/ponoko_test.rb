require 'pp'

def hr label
  puts '-' * 80
  puts label
  puts '-' * 80
end

$:.push File.dirname(__FILE__) + '/../lib/'
require 'ponoko'

hr "#{Ponoko::VERSION} (#{Ponoko::API_VERSION})"

hr "Using OAuth"
Ponoko.api = Ponoko::OAuthAPI.new env:             :sandbox,
                                  consumer_key:    'd2KxglROLzixJ53NAwTRVoAVMsmJZ5X7BxjfS7fc', 
                                  consumer_secret: 'vUk5HwgoGBe95P6zfyNrkW4Mkjojvkw84sd6BXik',
                                  access_token:    'Obq8aJ4O7Y8XCfkB1eFUjRMtRILPIfXiA80WvGnd', 
                                  access_secret:   'hNUeBfLcoz5K72TPRO3nW3Ovw7fcjzqyp84NzT7X'

# hr "Using Basic Auth"
# Ponoko.api = Ponoko::BasicAPI.new :env => :sandbox,
#                                   :app_key => 'f311cc5bbef182b12ea35dfb143f7edd', 
#                                   :user_access_key => 'fef1fedc13c20d58233617d276fa2381'



hr "Nodes"
nodes = Ponoko::Node.get!
pp nodes

node = Ponoko::Node.get! nodes.last.key
pp node

mc = node.material_catalogue
# pp mc


hr "Products"
pp products = Ponoko::Product.get!

old_product = Ponoko::Product.get! products.first.key unless products.empty?

pp old_product

# old_product.add_design_image! File.new(File.dirname(__FILE__) + "/Fixtures/lamp-1_product_page.jpg")

new_product = Ponoko::Product.new 'ref' => 'product_ref-' + Time.new.to_s, 'name' => 'Product', 'description' => 'This is a product description'

file = File.new(File.dirname(__FILE__) + "/Fixtures/exclamation_lamp/3mm_acrylic-191x191mm.svg")
design = Ponoko::Design.new 'ref' => '42', 'design_file' => file

material = mc['Plastic']['Acrylic']['Red']['3.0 mm']['P2']
pp material
design.add_material material

new_product.add_designs design

hr "Create Product"
new_product.send!
pp new_product

hr "Update Design"
design = new_product.designs.first
design.add_material mc['Plastic']['Acrylic']['Blue']['3.0 mm']['P1']
design.quantity = 3

# new_product.update_design! design

pp new_product.designs

hr "Design Image"
new_product.add_design_image! File.new(File.dirname(__FILE__) + "/Fixtures/lamp-1_product_page.jpg")
pp new_product.design_images

hr "Assembly Instructions"
new_product.add_assembly_instructions! 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
pp new_product.assembly_instructions

hr "Hardware"
new_product.add_hardware! 'COM-00680', 2
pp new_product.hardware

hardware = new_product.hardware.first
hardware.quantity = 1
new_product.update_hardware! hardware
pp new_product.hardware

pp new_product

# new_product.remove_design_image! 'lamp-1_product_page.jpg'
# new_product.remove_assembly_instructions! 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
# new_product.remove_hardware! 'COM-00680'

# pp new_product

new_product.delete!

hr "Orders"
orders = Ponoko::Order.get!
pp orders

pp Ponoko::Order.get! orders.first.ref unless orders.empty?

address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}

order = Ponoko::Order.new 'ref' => 'order_ref97-' + Time.new.to_s, 'delivery_address' => address

order.add_product products.first

hr "Get the shipping options"
shipping_options = order.shipping_options!

pp shipping_options

order.shipping_option_code = shipping_options.first['code'] 

hr "Send the order"
order.send!

pp order

hr "Get the order status"
pp order.status

hr "Step the order"
Ponoko::Sandbox::step_order order

pp order.status

