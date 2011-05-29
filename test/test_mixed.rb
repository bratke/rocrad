begin
  require "helper"
rescue LoadError
  require File.dirname(__FILE__) + '/helper'
end

class TestMixed < Test::Unit::TestCase

  def setup
    @path    = Pathname.new(__FILE__.gsub("test_mixed.rb", "")).expand_path
    @tif     = @path.join("images", "mixed.tif").to_s
    @txt_tif = "43ZZ".downcase
  end

  def test_should_be_instantiable
    assert_equal Rocrad::Mixed, Rocrad::Mixed.new.class
    assert_equal Rocrad::Mixed, Rocrad::Mixed.new(@tif).class
  end

  def test_should_translate_parts_of_the_image_to_text
    mix_block = Rocrad::Mixed.new(@tif) do |image|
      image.add_area(28, 19, 25, 25) #position of 4
      image.add_area(180, 22, 20, 28) # position of 3
      image.add_area(218, 22, 24, 28) # position of z
      image.add_area(248, 24, 22, 22) # position of z
    end
    assert_equal @txt_tif, mix_block.to_s.gsub(/[ \n\r]/, "")

    mix_block = Rocrad::Mixed.new(@tif, {:areas => [
        {:x => 28, :y=>19, :w=>25, :h=>25}, #position of 4
        {:x => 180, :y=>22, :w=>20, :h=>28}, # position of 3
        {:x => 218, :y=>22, :w=>24, :h=>28}, # position of z
        {:x => 248, :y=>24, :w=>22, :h=>22} # position of z
    ]})
    assert_equal @txt_tif, mix_block.to_s.gsub(/[ \n\r]/, "")
  end

  def test_show_areas

    mix_block = Rocrad::Mixed.new(@tif) do |image|
      image.add_area(28, 19, 25, 25) #position of 4
      image.add_area(180, 22, 20, 28) # position of 3
      image.add_area(218, 22, 24, 28) # position of z
      image.add_area(248, 24, 22, 22) # position of z
    end

    areas     = [{:x=>28, :h=>25, :w=>25, :y=>19},
                 {:x=>180, :h=>28, :w=>20, :y=>22},
                 {:x=>218, :h=>28, :w=>24, :y=>22},
                 {:x=>248, :h=>22, :w=>22, :y=>24}]
    assert_equal(areas, mix_block.areas)
  end

  def test_show_areas2
    mix_block = Rocrad::Mixed.new(@tif, {:areas => [
        {:x => 28, :y=>19, :w=>25, :h=>25}, #position of 4
        {:x => 180, :y=>22, :w=>20, :h=>28}, # position of 3
        {:x => 218, :y=>22, :w=>24, :h=>28}, # position of z
        {:x => 248, :y=>24, :w=>22, :h=>22} # position of z
    ]})

    areas     = [{:x=>28, :h=>25, :w=>25, :y=>19},
                 {:x=>180, :h=>28, :w=>20, :y=>22},
                 {:x=>218, :h=>28, :w=>24, :y=>22},
                 {:x=>248, :h=>22, :w=>22, :y=>24}]
    assert_equal(areas, mix_block.areas)
  end

  def test_edit_areas
    mix_block       = Rocrad::Mixed.new(@tif, {:areas => [
        {:x => 28, :y=>19, :w=>25, :h=>25}, #position of 4
        {:x => 180, :y=>22, :w=>20, :h=>28}, # position of 3
        {:x => 218, :y=>22, :w=>24, :h=>28}, # position of z
        {:x => 248, :y=>24, :w=>22, :h=>22} # position of z
    ]})

    mix_block.areas = mix_block.areas[1..3]
    areas           = [{:x=>180, :h=>28, :w=>20, :y=>22},
                       {:x=>218, :h=>28, :w=>24, :y=>22},
                       {:x=>248, :h=>22, :w=>22, :y=>24}]
    assert_equal(areas, mix_block.areas)
    assert_equal @txt_tif[1..3], mix_block.to_s.gsub(/[ \n\r]/, "")

    mix_block.areas = []
    assert_equal([], mix_block.areas)
    assert_equal "", mix_block.to_s.gsub(/[ \n\r]/, "")

    mix_block.areas = nil
    assert_equal([], mix_block.areas)
    assert_equal "", mix_block.to_s.gsub(/[ \n\r]/, "")
  end

end


