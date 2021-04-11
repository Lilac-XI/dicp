class ImageSizeFormatter
    require 'rmagick'
    class << self
        def resize(images)
            top = Magick::Image.read(images.first.path).first
            columns = images.map do |image|
                Magick::Image.read(image.path).first.columns.to_i
            end
        end
    end
end