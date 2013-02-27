module Paperclip
  class ItemProcessor < Processor

    class VideoGeometry < Geometry
      def self.parse_ffprobe(ffprobe_output)
        size = ffprobe_output[/Stream.*Video.*\n/, 0].split(', ').slice(2)
        g = parse(size)
        VideoGeometry.new(g.width, g.height, g.modifier)
      end


      def transformation_to dst, crop = false
        if (self.horizontal? and self.width > dst.width) or (self.vertical? and self.height < dst.height)
          nh = (self.height / ( self.width / dst.width.to_f )).to_i
          offset = (dst.height - nh)
          [ VideoGeometry.new(dst.width, nh),
            VideoGeometry.new(dst.width, dst.height), 
            VideoGeometry.new(0, offset) ]
        else
          nw = (self.width / ( self.height / dst.height.to_f )).to_i
          offset = (dst.width - nw)
          [ VideoGeometry.new(nw, dst.height),
            VideoGeometry.new(dst.width, dst.height), 
            VideoGeometry.new(offset, 0) ]
        end
      end

      def to_s
        "#{self.width.to_i}:#{self.height.to_i}"
      end
    end

    FFMPEG = '/usr/bin/ffmpeg'
    FFPROBE = '/usr/bin/ffprobe'
    JAVA = '/usr/bin/java'
    JOD = '/usr/share/java/jodconverter/jodconverter-cli-2.2.2.jar'
    attr_reader :format

    def initialize(file, options = {}, attachment = nil)
      @file = file
      @geometry = Geometry.parse(options[:geometry])
      @crop = (@geometry.to_s[-1] == '#')
      @format = options[:format] || :png

      @attachment = attachment

      @current_format = File.extname(@file.path)
      @basename = File.basename(@file.path, @current_format)
    end

    def ffmpeg(params = '', options = {})
      Paperclip.run(FFMPEG, "#{params} 2>&1", options, log_command: true)
    end

    def ffprobe(filepath)
      Paperclip.run(FFPROBE, '-i :file 2>&1', file: filepath, log_command: true)
    end

    def jodconvert(params = '', options = {})
      Paperclip.run("#{JAVA} -jar #{JOD}", params, options, log_command: true)
    end

    def make
      item = @attachment.instance

      if item.video?
        process_video
      elsif item.document?
        process_document
      elsif item.image?
        process_image
      else
        process_item
      end
    end

    def process_video
      dst = Tempfile.new([@basename, ".#{@format}"])
      
      if format == :png
        img = Tempfile.new(["#{@basename}_preview", ".#{@format}"]) 

        ffmpeg('-y -itsoffset -4 -i :src -vcodec mjpeg -vframes 1 -an -f rawvideo :img',
               src: File.expand_path(@file.path),
               img: File.expand_path(img.path) )

        current_geometry = Geometry.from_file(img)
        scale, crop = current_geometry.transformation_to(@geometry, @crop)
        command = [ ':src' ]
        command << '-resize' << "'#{scale}'"
        command << '-crop' << "'#{crop}'" if crop
        command << ':dst'

        convert(command.join(' '), 
                src: File.expand_path(img.path),
                dst: File.expand_path(dst.path) )

      elsif [:mp4, :flv].include? format
        ffmpeg(video_transformation_command(format), 
               src: File.expand_path(@file.path),
               dst: File.expand_path(dst.path) )
      end

      dst
    end

    def video_transformation_command(output_format = :mp4)
        current_geometry = VideoGeometry.parse_ffprobe(ffprobe(@file.path))
        scl, pad, off = current_geometry.transformation_to @geometry
        vf = "'scale=#{scl},pad=#{pad}:#{off}'"

        case output_format
        when :flv then "-y -i :src -ar 44100 -ab 96k -vf #{vf} -f flv :dst"
        when :mp4 then "-y -i :src -acodec aac -b:a 96k -level 21 -refs 2 -b:v 345k -vf #{vf} -vcodec libx264 -f mp4 -strict -2 :dst"
        else "-y -i :src :dst"
        end
    end

    def process_document
      dst = Tempfile.new([@basename, ".#{@format.to_s}"])

      if format == :png
        pdf = Tempfile.new([@basename, '.pdf'])
        jodconvert(':src :dst', src: File.expand_path(@file.path), dst: File.expand_path(pdf.path))

        current_geometry = Geometry.from_file(pdf)
        scale, crop = current_geometry.transformation_to(@geometry, @crop)

        command = []
        command << '-density' << '200'
        command << ':src'
        command << '-resize' << "'#{scale}'"
        command << '-crop' << "'#{crop}'" if crop
        command << ':dst'

        convert(command.join(' '), 
                src: "#{File.expand_path(pdf.path)}[0]",
                dst: File.expand_path(dst.path) )

        
      elsif format == :pdf
        jodconvert(':src :dst', src: File.expand_path(@file.path), dst: File.expand_path(dst.path))
      end

      dst
    end


    def process_image
      dst = Tempfile.new([@basename, @format.to_s])

    end

    def process_item
      dst = Tempfile.new([@basename, @format.to_s])

    end
  end
end
