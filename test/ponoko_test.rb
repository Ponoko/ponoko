require 'pp'

def hr label
  puts '-' * 80
  puts label
  puts '-' * 80
end

$:.push File.dirname(__FILE__) + '/../lib/'
require 'ponoko'

hr Ponoko::VERSION

Ponoko.api = Ponoko::OAuthAPI.new env:             :sandbox,
                                  consumer_key:    'd2KxglROLzixJ53NAwTRVoAVMsmJZ5X7BxjfS7fc', 
                                  consumer_secret: 'vUk5HwgoGBe95P6zfyNrkW4Mkjojvkw84sd6BXik',
                                  access_token:    'Obq8aJ4O7Y8XCfkB1eFUjRMtRILPIfXiA80WvGnd', 
                                  access_secret:   'hNUeBfLcoz5K72TPRO3nW3Ovw7fcjzqyp84NzT7X'


# Ponoko.api = Ponoko::OAuthAPI.new env:             :test,
#                                   consumer_key:    'mgaFFoAzbnc7I4pOitGWf9ATECzDElfZB072ugmR', 
#                                   consumer_secret: 'yivct1T8KciWG2astV5ljPsYTjkEGwNIckOUOikS',
#                                   access_token:    'OZwmvuSbijjMRRvlFH3vYD7tnZCyLiXVaSmtblHr', 
#                                   access_secret:   'bOAI6FJx1m8QbhPbAxy19orvCf9y1Kbk5rNinhyg'


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

# new_product.add_design_image! File.new(File.dirname(__FILE__) + "/Fixtures/lamp-1_product_page.jpg")
new_product.add_assembly_instructions! 'http://www.instructables.com/id/3D-print-your-minecraft-avatar/'
new_product.add_hardware! 'COM-00680', 2

pp new_product

new_product.delete

exit

hr "Orders"
orders = Ponoko::Order.get!
pp orders

pp Ponoko::Order.get! orders.first.ref unless orders.empty?

address = {"first_name" => "John", "last_name" => "Brown", "address_line_1"=>"27 Dixon Street", "address_line_2"=>"Te Aro", "city"=>"Wellington", "state"=>"na", "zip_or_postal_code"=>"6021", "country"=>"New Zealand", "phone_number" => "045678910"}

order = Ponoko::Order.new 'ref' => 'order_ref97', 'delivery_address' => address, 'shipping_option_code' => 'ups_saver'

order.add_product products.first

shipping_options = order.shipping_options!

pp shipping_options

pp order

order.send!

pp order

pp order.status

Ponoko::Sandbox::step_order order

pp order.status

