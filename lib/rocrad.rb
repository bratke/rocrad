require "pathname"
require "tempfile"
require "uuid"
require "net/http"

require "rocrad/errors"

class Rocrad

  attr_accessor :options


  def initialize(src="", options={})
    @uid                  = UUID.new
    @source               = get_source src
    @clear_console_output = options.delete(:clear_console_output)
    @clear_console_output = true if @clear_console_output.nil?
    @value = ""
  end

  def source= src=""
    @value  = ""
    @source = get_source src
  end

  #TODO: Clear console for MacOS or Windows
  def clear_console_output
    return "" unless @clear_console_output
    "2>/dev/null" if File.exist?("/dev/null") #Linux console clear
  end

  #Output value
  def to_s
    return @value if @value != ""
    if @source.instance_of? Pathname and @source.file?
      convert
      @value
    elsif @source.instance_of? URI::HTTP
      convert_via_http
      @value
    else
      raise ImageNotSelectedError
    end
  end

  #Remove spaces and break-lines
  def to_s_without_spaces
    to_s.gsub(" ", "").gsub("\n", "").gsub("\r", "")
  end

  private

  def convert_via_http
    tmp_path = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{Pathname.new(@source.request_uri).basename}")
    tmp_file = File.new(tmp_path.to_s, File::CREAT|File::TRUNC|File::RDWR, 0644)
    tmp_file.write(Net::HTTP.get(@source))
    tmp_file.close
    uri     = @source
    @source = tmp_path
    convert
    @source = uri
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
        system "rm -f #{file}"
      end
    end
    true
  rescue
    raise Rocrad::TempFilesNotRemovedError
  end

  #Convert image to pnm
  def image_to_pnm
    pnm_image   = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{@source.sub(@source.extname, ".pnm").basename}")
    redirection = "#{@source} > #{pnm_image} #{clear_console_output}"
    case @source.extname
      when ".jpg" then
        `djpeg -greyscale -pnm #{redirection}`
      when ".tif" then
        `tifftopnm #{redirection}`
      when ".png" then
        `pngtopnm #{redirection}`
      when ".bmp" then
        `bmptopnm #{redirection}`
      else
        raise UnsupportedFileTypeError
    end
    pnm_image
  end

  #Convert image to string
  def convert
    txt_file  = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{@source.sub(@source.extname, ".txt").basename}")
    pnm_image = image_to_pnm
    begin
      `gocr #{pnm_image} -o #{txt_file} #{clear_console_output}`
      @value = File.read(txt_file)
      remove_file([pnm_image, txt_file])
    rescue
      raise ConversionError
    end
  end

end
