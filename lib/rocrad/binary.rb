class Rocrad
  class Binary < Rocrad

    def initialize(src="", filename="")
      @filename=filename
      super(src)
    end

    private

    def build_source(src)
      src_path = Pathname.new(Dir::tmpdir).join("#{@uid.generate}_#{@filename}")
      src_file = File.new(src_path.to_s, File::CREAT|File::TRUNC|File::RDWR, 0644)
      src_file.write(src)
      src_file.close
      Pathname.new(src_path)
    end

  end
end
