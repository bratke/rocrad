require "pathname"
require "tempfile"
require "uuid"
require "net/http"
require "RMagick"

require "rocrad/errors"
require "rocrad/mixed"
require "rocrad/binary"

class Rocrad

  attr_accessor :src
  attr_reader :tmp, :txt

  def initialize(src="")
    @uid = UUID.new
    @src = build_source src
    @txt = ""
    @tmp = nil
  end

  def src=(value="")
    @txt = ""
    @src = build_source value
  end

  def ocr!
    if @src.instance_of? Pathname and @src.file?
      ocr_via_path
      @txt
    elsif @src.instance_of? URI::HTTP
      ocr_via_http
      @txt
    else
      raise ImageNotSelectedError
    end
  end

  #Output value
  def to_s
    @txt != "" ? @txt : ocr!
  end

#Crop image to convert
  def crop!(x, y, w, h)
    @txt = ""
    src  = Magick::Image.read(@src.to_s).first
    src.crop!(x, y, w, h)
    @tmp = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{@src.sub(@src.extname, "-crop#{@src.extname}").basename}")
    src.write @tmp.to_s
    self
  end

  private

  #Linux console clear
  def cco
    File.exist?("/dev/null") ? "2>/dev/null" : ""
  end

  def ocr_via_http
    tmp_path = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{Pathname.new(@src.request_uri).basename}")
    tmp_file = File.new(tmp_path.to_s, File::CREAT|File::TRUNC|File::RDWR, 0644)
    tmp_file.write(Net::HTTP.get(@src))
    tmp_file.close
    uri  = @src
    @src = tmp_path
    ocr_via_path
    @src = uri
    remove_file([tmp_path])
  end

  def build_source(src)
    case (uri = URI.parse(src)).class.to_s
      when "URI::HTTP" then
        uri
      when "URI::Generic" then
        Pathname.new(uri.path)
      else
        Pathname.new(src)
    end
  end

  #Remove files
  def remove_file(files=[])
    files.each do |file|
      begin
        File.unlink(file) if File.exist?(file)
      rescue
        system "rm -f #{file} #{cco}"
      end
    end
  end

  #Convert image to pnm
  def image_to_pnm
    src = @tmp ? @tmp : @src
    pnm = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{@src.sub(@src.extname, ".pnm").basename}")
    case @src.extname
      when ".jpg" then
        `djpeg -colors 2 -grayscale -dct float -pnm #{src} > #{pnm} #{cco}`
      when ".tif" then
        `tifftopnm #{src} > #{pnm} #{cco}`
      when ".png" then
        `pngtopnm  #{src} > #{pnm} #{cco}`
      when ".bmp" then
        `bmptopnm #{src} > #{pnm} #{cco}`
      else
        raise UnsupportedFileTypeError
    end
    pnm
  end

  #Convert image to string
  def ocr_via_path
    src = @tmp ? @tmp : @src
    txt = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{src.sub(src.extname, ".txt").basename}")
    pnm = image_to_pnm
    `ocrad #{pnm} -l -F utf8 -o #{txt} #{cco}`
    @txt = File.read(txt)
    @tmp ? remove_file([pnm, txt, @tmp]) : remove_file([pnm, txt])
    @tmp = nil
  end

end
