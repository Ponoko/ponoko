require 'pp'

$:.push File.dirname(__FILE__) + '/../lib/'
require 'ponoko'


Ponoko.api = Ponoko::OAuthAPI.new env:             :sandbox,
                                  consumer_key:    '', 
                                  consumer_secret: '',
                                  access_token:    '', 
                                  access_secret:   ''


p "##############################"
p "Nodes"
p "##############################"

nodes = Ponoko::Node.get!
pp nodes

node = Ponoko::Node.get! nodes.last.key
pp node

mc = node.material_catalogue
pp mc


p "##############################"
p "Products"
p "##############################"

pp products = Ponoko::Product.get!

pp Ponoko::Product.get! products.first.ref unless products.empty?

product = Ponoko::Product.new 'ref' => 'product_ref', 'name' => 'Product', 'description' => 'This is a product description'

file = File.new(File.dirname(__FILE__) + "/Fixtures/exclamation_lamp/3mm_acrylic-191x191mm.svg")
design = Ponoko::Design.new 'ref' => '42', 'design_file' => file

material = mc['Plastic']['Acrylic']['Red']['3.0 mm']['P2']
pp material
design.add_material material

product.add_designs design

product.send!
pp product


p "##############################"
p "Orders"
p "##############################"


orders = Ponoko::Order.get!
pp orders

order = Ponoko::Order.get! orders.first.ref
pp order

pp order.status!

Ponoko::Sandbox::step_order order

pp order.status!


=begin
address = Ponoko::Address.new 'John', 'Brown', '27 Dixon Street', 'Te Aro', 'Wellington', 'na', '6021', 'New Zealand', '+6421782215'

order = Ponoko::Order.new 'ref' => 'order_ref97', 'delivery_address' => address, 'shipping_option_code' => 'ups_saver'

order.add_product products.first

pp order

=end

=begin
order.send!

pp order
=end

