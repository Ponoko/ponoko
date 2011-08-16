require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class Test_MaterialCatalogue < MiniTest::Unit::TestCase
  def test_construct_material_catalogue
    m = Ponoko::MaterialCatalogue.new
    raw_data = [{"updated_at" => "2011/03/17 02:08:51 +0000","type" => "P1","weight" => "0.1 kg","color" => "Fuchsia","key" => "6812d5403269012e2f2f404062cdb04a","thickness" => "3.0 mm","name" => "Felt","width" => "181.0 mm","material_type" => "sheet","length" => "181.0 mm","kind" => "Fabric"},
                {"updated_at" => "2011/03/17 02:08:51 +0000","type" => "P2","weight" => "0.3 kg","color" => "Fuchsia","key" => "68140dc03269012e2f31404062cdb04a","thickness" => "3.0 mm","name" => "Felt","width" => "384.0 mm","material_type" => "sheet","length" => "384.0 mm","kind" => "Fabric"}]
      
    materials = raw_data.collect do |r|
      m.make_material r
    end        
    
    assert_equal 2, m.materials.length
    assert_equal "Fuchsia", m.materials[1].color
    assert_equal "P2", m.materials[1].type

#     "#{@kind}, #{@name}, #{@color}, #{@thickness}, #{@type}"    
    assert_equal m.materials[1], m['Fabric']['Felt']['Fuchsia']['3.0 mm']['P2']
  end
end
