begin
  require "helper"
rescue LoadError
  require File.dirname(__FILE__) + '/helper'
end

class TestRocrad < Test::Unit::TestCase

  def setup
    @path      = Pathname.new(__FILE__.gsub("test_rocrad.rb", "")).expand_path
    @image_jpg = @path.join("images", "test.jpg").to_s
    f          = File.open(@image_jpg.to_s, "r")
    @chars     = f.chars.to_a
    f.close
  end

  def test_convert_via_http
    Net::HTTP.expects(:get).returns(@chars)
    assert_equal "3R8Z", Rocrad.new("http://localhost:3000/uploads/picture/data/4dd21bfd828bf81bdd00000d/nzp_img_17_4_2011_8_55_29.jpg").to_s_without_spaces
  end

  def test_convert_via_http_raise_exception
    assert_raise Errno::ECONNREFUSED do
      Rocrad.new("http://localhost:3000/uploads/picture/data/4dd21bfd828bf81bdd00000d/nzp_img_17_4_2011_8_55_29.jpg").to_s_without_spaces
    end
  end

  def test_be_instantiable
    assert_equal Rocrad, Rocrad.new.class
    assert_equal Rocrad, Rocrad.new("").class
    assert_equal Rocrad, Rocrad.new(@image_jpg).class
  end

  def test_translate_image_to_text
    assert_equal "3R8Z", Rocrad.new(@image_jpg).to_s_without_spaces
    assert_equal "43ZZ", Rocrad.new(@path.join("images", "test.tif").to_s).to_s_without_spaces
  end

  def test_unsupported_file_type_error
    assert_raise Rocrad::UnsupportedFileTypeError do
      Rocrad.new(@path.join("images", "test.foo").to_s).to_s_without_spaces
    end
  end

  def test_image_not_selected_error
    assert_raise Rocrad::ImageNotSelectedError do
      Rocrad.new(@path.join("images", "test.noo").to_s).to_s_without_spaces
    end
  end

  def test_translate_images_png_jpg
    assert_equal "HW9W", Rocrad.new(@path.join("images", "test.png").to_s).to_s_without_spaces
    assert_equal "3R8Z", Rocrad.new(@path.join("images", "test.jpg").to_s).to_s_without_spaces
  end

  def test_translate_images_bmp
    pend
    assert_equal "ZLA6", Rocrad.new(@path.join("images", "test.bmp").to_s).to_s_without_spaces
  end

  def test_translate_mixed_tif
    pend
    assert_equal "43ZZ", Rocrad.new(@path.join("images", "mixed.tif").to_s).to_s_without_spaces
  end

  def test_translate_test1_tif
    pend
    assert_equal "V2V4", Rocrad.new(@path.join("images", "test1.tif").to_s).to_s_without_spaces
  end

  def test_change_the_image
    image = Rocrad.new(@image_jpg)
    assert_equal "3R8Z", image.to_s_without_spaces
    image.source = @path.join("images", "test.tif").to_s
    assert_equal "43ZZ", image.to_s_without_spaces
  end

  def test_unique_uid
    assert_not_equal Rocrad.new(@image_jpg).instance_variable_get(:@uid).generate,
                     Rocrad.new(@image_jpg).instance_variable_get(:@uid).generate
  end

  def test_generate_a_unique id
    reg = Rocrad.new(@image_jpg)
    assert_equal reg.generate_uid, reg.generate_uid
    value = reg.generate_uid
    reg.convert
    assert_not_equal value, reg.generate_uid
  end

end
