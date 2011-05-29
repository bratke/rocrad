class Rocrad
  class Mixed < Rocrad

    attr_accessor :areas

    def initialize(src="", options = {})
      super(src)
      @areas = options.delete(:areas) || []
      yield self if block_given?
    end

    def add_area(x, y, w, h)
      @txt = ""
      @areas << {:x => x, :y => y, :w => w, :h => h}
    end

    def areas=(value)
      @areas = value.instance_of?(Array) ? value : []
      @areas.delete_if { |area| !area.is_a?(Hash) or !area.has_key?(:x) or !area.has_key?(:y) or
          !area.has_key?(:w) or !area.has_key?(:h) }
      @txt = ""
    end

    private

    #Convert parts of image to string
    def ocr!
      @txt = ""
      @areas.each do |area|
        image = Rocrad.new(@src.to_s)
        image.crop!(area[:x].to_i, area[:y].to_i, area[:w].to_i, area[:h].to_i)
        @txt << image.to_s
      end
      @txt
    end

  end
end

