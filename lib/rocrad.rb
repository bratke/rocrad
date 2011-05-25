require "pathname"
require "tempfile"

require "rocrad/errors"

class Rocrad

  attr_accessor :options

  def initialize(src="", options={})
    @uid                  = options.delete(:uid) || nil
    @source               = Pathname.new src
    @clear_console_output = options.delete(:clear_console_output)
    @clear_console_output = true if @clear_console_output.nil?
    @value = ""
  end

  def source= src
    @value  = ""
    @source = Pathname.new src
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

  def generate_uid
    @uid = rand.to_s[2, 10] if @uid.nil?
    @uid
  end

  #Convert image to pnm
  def image_to_pnm
    generate_uid
    tmp_file    = Pathname.new(Dir::tmpdir).join("#{@uid}_#{@source.sub_ext(".pnm").basename}")
    redirection = "#{@source} > #{tmp_file} #{clear_console_output}"
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
    tmp_file
  end

  #Convert image to string
  def convert
    generate_uid
    tmp_file  = Pathname.new(Dir::tmpdir).join("#{@uid}_#{@source.sub_ext(".txt").basename}")
    tmp_image = image_to_pnm
    `gocr #{tmp_image} -o #{tmp_file} #{clear_console_output}`
    @value = File.read(tmp_file)
    @uid   = nil
    remove_file([tmp_image, tmp_file])
  rescue
    raise Rocrad::ConversionError
  end

  #TODO: Clear console for MacOS or Windows
  def clear_console_output
    return "" unless @clear_console_output
    "2>/dev/null" if File.exist?("/dev/null") #Linux console clear
  end

  #Output value
  def to_s
    return @value if @value != ""
    if @source.file?
      convert
      @value
    else
      raise Rocrad::ImageNotSelectedError
    end
  end

  #Remove spaces and break-lines
  def to_s_without_spaces
    to_s.gsub(" ", "").gsub("\n", "").gsub("\r", "").encode("US-ASCII")
  end

end
