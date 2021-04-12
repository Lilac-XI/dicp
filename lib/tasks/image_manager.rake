namespace :image_manager do
    desc "pdf url add database"
    task :set_url, ['url'] => :environment do |task, args|
        url = args["url"]
        check = Pdf.find_by(url: url)
        if check.nil? && url != "" && !url.nil?
            Pdf.create(url: url)
            puts "set pdf"
        else
            puts "dont set pdf"
        end
    end

    desc "list image from Pdf.url"
    task list_image: :environment do
        sites = SpecificSiteFormatter.methods(false)
        agent = Mechanize.new
        pdfs = Pdf.where(image_size: nil)
        pdfs.each do |pdf|
            dir_path = "#{Rails.root.join}/results/#{pdf.id}"
            if !Dir.exist?("#{dir_path}")
            Dir.mkdir("#{dir_path}")
            end
            body = nil
            threshold = 0.8
            file_name = "#{pdf.id}"
            sites.each do |site_name|
                if pdf.url.include?(site_name.to_s)
                    file_name = SpecificSiteFormatter.send(site_name, pdf.url)
                    break
                end
            end
            # if body.nil?
            #     body = agent.get(pdf.url).body
            # end
            # puts "-----------------"
            # image_tags = body.scan(/<img.*?>/)
            # image_links = URLFormatter.shape_image_tags(image_tags)
            body = agent.get(pdf.url)
            images = body.images.map {|img| img.src}
            image_links = Array.new
            body.images.each do |img|
                if img.src.start_with?("http")
                    image_links << img.src
                end
            end

            sleep 1
            similar_links = URLFormatter.split_similars(image_links, threshold)
            sleep 1
            urls = similar_links.max
            puts urls
            puts "-----------------"
            puts file_name
            urls.each_with_index do |image_url,i|
                image_path = "#{dir_path}/#{i+1}.jpg"
                Image.create(pdf_id: pdf.id, url: image_url,path: image_path)
                puts "#{image_path} finish"
            end
            pdf.update(file_name: file_name, image_size: pdf.images.size, path: "#{Rails.root.join}/results/#{file_name}.pdf")
        end
    end

    desc "404 checker"
    task url_check: :environment do
        images = Image.where(access_success: nil).order(updated_at: "ASC").limit(50)
        Parallel.each(images, in_processes: 50) do |image|
            agent = Mechanize.new
            begin
                agent.read_timeout = 15
                agent.open_timeout = 15
                puts "#{image.url} check start url"
                agent.get(image.url)
                image.update(access_success: true)
                
            rescue Mechanize::ResponseCodeError => e
                puts "#{image.url} #{e}"
                case e.response_code
                when 404
                    image.update(access_success: false)
                else
                    puts "#{image.url} #{e}"
                    image.touch
                    image.save
                end
            rescue => e
                puts "#{image.url} #{e}"
                image.touch
                image.save
            end
            agent.shutdown
        end
    end

    desc "cant access url check png <= => jpg"
    task png_jpg_change_test: :environment do
        images = Image.where(access_success: false)
        agent = Mechanize.new
        agent.read_timeout = 15
        agent.open_timeout = 15
        images.each do |image|
            puts image.url
            if image.url.include?("jpg")
                image.url.gsub!("jpg", "png")
            elsif image.url.include?("png")
                image.url.gsub!("png", "jpg")
            end
            puts image.url
        end
        
        Parallel.each(images, in_processes: 50) do |image|
            begin
                puts "#{image.url} check start png_jpg"
                agent.get(image.url)
                puts "#{image.url} success"
                image.update(access_success: true, url: image.url)
            rescue Mechanize::ResponseCodeError => e
                puts "#{image.url} #{e.response_code}"
                if  e.response_code.to_s == "404"
                    puts "404発生"
                    image.reload
                    image.update(access_success: nil)
                else #404以外のエラー →タイムアウト
                    image.save
                    puts "#{image.url} #{e}"
                end
            rescue => e 
                puts "#{image.url} #{e}"
                image.save
            end
        end
    end

    desc "download image"
    task download_image: :environment do
        images = Image.where(downloaded: false, access_success: true).order(updated_at: "ASC").limit(50)
        
        # images = Pdf.find(34).images
        Parallel.each(images, in_processes: 50) do |image|
            begin
                agent = Mechanize.new
                puts "#{image.url} start"
                agent.get(image.url).save_as(image.path)
                image.update(downloaded: true)
                puts "#{image.path} finish"
            rescue => e
                puts "#{image.url} #{e}"
                image.update(downloaded: false, access_success: nil)
                puts "update"
            end
        end
    end

    desc "images info formatter"
    task change_size_resolution: :environment do
        # pdfs = Pdf.where(created: false, resized: false).limit(3)
        pdfs = Pdf.where(id: 34)
        pdfs.each do |pdf|
            puts "#{pdf.file_name} resize start"
            images = pdf.images
            column = 0
            resolution = 0
            images.each do |image|
                image_file = Magick::Image.read(image.path).first
                if image_file.rows > image_file.columns
                    puts "#{image.url} is kijun"
                    image_file.units = Magick::PixelsPerInchResolution
                    image_file.resample!(96)
                    column = image_file.columns
                    break
                end
            end
            images.each do |image|
                begin
                    puts "#{image.url} resize start"
                    path = "#{image.path.split(".")[0]}-resize.jpg"
                    image_file = Magick::Image.read(image.path).first
                    image_file.units = Magick::PixelsPerInchResolution
                    image_file.resample!(96)
                    row = column*image_file.rows/image_file.columns
                    image_file.resize!(column,row)
                    image_file.class_type = Magick::DirectClass
                    image_file.write(path){
                        self.quality = 100
                    }
                    image.update(path: path)
                    puts "#{image.url} resize finish"
                end
            end
            pdf.update(resized: true)
        end
    end

    desc "create pdf"
    task create_pdf: :environment do
        #pdfs = Pdf.where(created: false, resized: true).limit(5)
        pdfs = Pdf.where(id:34)
        pdfs.each do |pdf|
            puts "#{pdf.id} start"
            images = Magick::ImageList.new
            if pdf.images.where(downloaded: false).size == 0
                puts "#{pdf.id} #{pdf.file_name} create"
                pdf.images.each_with_index do |image, i|
                    image_file = Magick::Image.read(image.path)[0]
                    images << image_file
                end
                images.write(pdf.path)
                pdf.update(created: true)
            end
        end
    end
    desc "reset"
    task reset: :environment do
        Image.all.destroy_all
        Pdf.all.update(image_size: nil, created: false, resized: false)
    end

    desc "resize reverse"
    task resize_reverse: :environment do
        images = Pdf.find(29).images
        images.each do |image|
            image.path.gsub!("-resize","")
            image.save
        end
    end
end
