begin
  require "helper"
rescue LoadError
  require File.dirname(__FILE__) + '/helper'
end

class TestRocrad < Test::Unit::TestCase

  def setup
    @path  = Pathname.new(__FILE__.gsub("test_rocrad.rb", "")).expand_path
    @jpg   = @path.join("images", "test.jpg").to_s
    f      = File.open(@jpg.to_s, "r")
    @chars = f.chars.to_a
    f.close
    @txt_jpg = ["3", "R", "8", "Z".downcase].* ""
    @txt_tif = "43ZZ".downcase
    @txt_png = ["H", "W", "9", "W".downcase].* ""
    @txt_bmp = ["Z".downcase, "L", "A", "6"].* ""
  end

  def test_pdf
    assert Rocrad.new(@path.join("images", "test.pdf")).to_s.include?("This is a test.")
  end

  def test_ps
    assert Rocrad.new(@path.join("images", "test.ps")).to_s.include?("This is a test.")
  end

  def test_convert_via_http
    Net::HTTP.expects(:get).returns(@chars)
    assert_equal @txt_jpg, Rocrad.new("http://localhost:3000/uploads/picture/data/4dd21bfd828bf81bdd00000d/nzp_img_17_4_2011_8_55_29.jpg").to_s.gsub(/[ \n\r]/, "")
  end

  def test_convert_via_http_raise_exception
    assert_raise Errno::ECONNREFUSED do
      Rocrad.new("http://localhost:3000/uploads/picture/data/4dd21bfd828bf81bdd00000d/nzp_img_17_4_2011_8_55_29.jpg").to_s.gsub(/[ \n\r]/, "")
    end
  end

  def test_be_instantiable
    assert_equal Rocrad, Rocrad.new.class
    assert_equal Rocrad, Rocrad.new("").class
    assert_equal Rocrad, Rocrad.new(@jpg).class
  end

  def test_translate_image_to_text
    assert_equal @txt_jpg, Rocrad.new(@jpg).to_s.gsub(/[ \n\r]/, "")
    assert_equal @txt_tif, Rocrad.new(@path.join("images", "test.tif").to_s).to_s.gsub(/[ \n\r]/, "")
  end

  def test_unsupported_file_type_error
    assert_raise Rocrad::UnsupportedFileTypeError do
      Rocrad.new(@path.join("images", "test.foo").to_s).to_s.gsub(/[ \n\r]/, "")
    end
  end

  def test_image_not_selected_error
    assert_raise Rocrad::ImageNotSelectedError do
      Rocrad.new(@path.join("images", "test.noo").to_s).to_s.gsub(/[ \n\r]/, "")
    end
  end

  def test_translate_images_png_jpg
    assert_equal @txt_png, Rocrad.new(@path.join("images", "test.png").to_s).to_s.gsub(/[ \n\r]/, "")
    assert_equal @txt_jpg, Rocrad.new(@path.join("images", "test.jpg").to_s).to_s.gsub(/[ \n\r]/, "")
  end

  def test_translate_images_bmp
    assert_equal @txt_bmp, Rocrad.new(@path.join("images", "test.bmp").to_s).to_s.gsub(/[ \n\r]/, "")
  end

  def test_translate_test1_tif
    assert_equal "V2V4".downcase, Rocrad.new(@path.join("images", "test1.tif").to_s).to_s.gsub(/[ \n\r]/, "")
  end

  def test_change_the_image
    image = Rocrad.new(@jpg)
    assert_equal @txt_jpg, image.to_s.gsub(/[ \n\r]/, "")
    image.src = @path.join("images", "test.tif").to_s
    assert_equal @txt_tif, image.to_s.gsub(/[ \n\r]/, "")
  end

  def test_unique_uid
    assert_not_equal Rocrad.new(@jpg).instance_variable_get(:@uid).generate,
                     Rocrad.new(@jpg).instance_variable_get(:@uid).generate
  end

  def test_should_crop_image_tif
    tif = @path.join("images", "test.tif").to_s
    assert_equal "4", Rocrad.new(tif).crop!(140, 10, 36, 40).to_s.gsub(/[ \n\r]/, "")
    assert_equal "3", Rocrad.new(tif).crop!(180, 10, 36, 40).to_s.gsub(/[ \n\r]/, "")
    assert_equal "Z".downcase, Rocrad.new(tif).crop!(200, 10, 36, 40).to_s.gsub(/[ \n\r]/, "")
    assert_equal "Z".downcase, Rocrad.new(tif).crop!(220, 10, 30, 40).to_s.gsub(/[ \n\r]/, "")
  end

  def test_should_crop_image_tif_same_instance
    tif      = @path.join("images", "test.tif").to_s
    instance = Rocrad.new(tif)
    assert_equal "4", instance.crop!(140, 10, 36, 40).to_s.gsub(/[ \n\r]/, "")
    assert_equal "3", instance.crop!(180, 10, 36, 40).to_s.gsub(/[ \n\r]/, "")
    assert_equal "Z".downcase, instance.crop!(200, 10, 36, 40).to_s.gsub(/[ \n\r]/, "")
    assert_equal "Z".downcase, instance.crop!(220, 10, 30, 40).to_s.gsub(/[ \n\r]/, "")
  end

  def test_attr_reader_while_cropping
    tif    = @path.join("images", "test.tif").to_s
    rocrad = Rocrad.new(tif).crop!(140, 10, 36, 40)
    assert_equal "", rocrad.txt
    assert rocrad.tmp.instance_of? Pathname
    assert_equal "4", rocrad.to_s.gsub(/[ \n\r]/, "")
    assert rocrad.txt.include?("4")
    assert_nil rocrad.tmp
  end

end
