require "pathname"
require "tempfile"
require "uuid"
require "net/http"
require "RMagick"

require "rocrad/errors"
require "rocrad/mixed"

class Rocrad

  attr_accessor :src
  attr_reader :tmp, :txt

  def initialize(src="")
    @uid = UUID.new
    @src = get_source src
    @txt = ""
    @tmp = nil
  end

  def src=(value="")
    @txt = ""
    @src = get_source value
  end

  #Output value
  def to_s
    return @txt if @txt != ""
    if @src.instance_of? Pathname and @src.file?
      convert
      @txt
    elsif @src.instance_of? URI::HTTP
      convert_via_http
      @txt
    else
      raise ImageNotSelectedError
    end
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

  def cco
    "2>/dev/null" if File.exist?("/dev/null") #Linux console clear
  end

  def convert_via_http
    tmp_path = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{Pathname.new(@src.request_uri).basename}")
    tmp_file = File.new(tmp_path.to_s, File::CREAT|File::TRUNC|File::RDWR, 0644)
    tmp_file.write(Net::HTTP.get(@src))
    tmp_file.close
    uri  = @src
    @src = tmp_path
    convert
    @src = uri
    remove_file([tmp_path])
  end

  def get_source(src)
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
    true
  rescue
    raise TempFilesNotRemovedError
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
  def convert
    src = @tmp ? @tmp : @src
    txt = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{src.sub(src.extname, ".txt").basename}")
    pnm = image_to_pnm
    begin
      `ocrad #{pnm} -l -F utf8 -o #{txt} #{cco}`
      @txt = File.read(txt)
      @tmp ? remove_file([pnm, txt, @tmp]) : remove_file([pnm, txt])
      @tmp = nil
    rescue
      raise ConversionError
    end
  end

end
