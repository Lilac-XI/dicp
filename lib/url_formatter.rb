module URLFormatter extend ActiveSupport::Concern
    require "open-uri"
    require "trigram"
    class << self
        def read_image_tags(url)
            OpenURI.open_uri(url).read.scan(/<img.*?>/)
        end

        def shape_image_tags(image_tags)
            image_urls = Array.new
            # タグを除去しurlに整形
            image_tags.each_with_index do |tag, i|
                image_urls[i] = tag.scan(/ src="http.*?"/).join
                image_urls[i].slice!(/ src="/)
                image_urls[i].slice!(/"/)
            end
            # 重複削除
            image_urls.uniq!
            image_urls.delete("")
            return image_urls
        end

        def split_similars(urls, threshold)
            similars = Array.new(urls.size-1)
            urls.each_with_index do |url,i|
                if i < similars.size
                    similars[i] = Trigram.compare url, urls[i+1]
                end
            end
            l = 0
            sl = 0
            similar_urls = Array.new
            similars.each_with_index do |num,i|
                if i == similars.size-1
                    similar_urls[sl] = urls[l..similars.size]
                elsif i >= l
                    if num < threshold
                        similar_urls[sl] = urls[l..i]
                        sl = sl+1
                        l = i+1
                    end
                end
            end

            similar_urls.delete_if do |urls|
                urls.size < 7
            end
            return similar_urls
        end
    end
end