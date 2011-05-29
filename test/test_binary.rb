begin
  require "helper"
rescue LoadError
  require File.dirname(__FILE__) + '/helper'
end

class TestBinary < Test::Unit::TestCase

  def setup
    @path  = Pathname.new(__FILE__.gsub("test_binary.rb", "")).expand_path
    @jpg   = @path.join("images", "test.jpg").to_s
    f      = File.open(@jpg.to_s, "r")
    @chars = f.chars.to_a
    f.close
    @txt_jpg = ["3", "R", "8", "Z".downcase].*""
  end

  def test_binary
    assert_equal @txt_jpg, Rocrad::Binary.new(@chars, "foo.jpg").to_s.gsub(/[ \n\r]/,"")
  end
end