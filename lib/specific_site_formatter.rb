class SpecificSiteFormatter
    require "open-uri"
    require "selenium-webdriver"

    class << self
        def erocool(url)
            puts "lazy start"
            Selenium::WebDriver::Chrome::Service.driver_path= "/usr/local/bin/chromedriver" #wslの場合、Cドライブ下にChome Driverを配置
            options = Selenium::WebDriver::Chrome::Options.new
            options.add_argument('--headless')
            driver = Selenium::WebDriver.for :chrome, options: options
            wait = Selenium::WebDriver::Wait.new(:timeout => 30)
            driver.navigate.to url

            lazyloads = Array.new #読まれていない画像
            wait.until {lazyloads = driver.find_elements(:class=> "lazyload")}

            lazyloads.each do |element|
                driver.execute_script("window.scroll(#{element.location.x},#{element.location.y});")
            end

            sleep 1
            body = driver.page_source
            driver.quit()
            puts "lazy end"
            page_titles = body.scan(/<h1>(.*?)<\/h1>/)
            file_name = page_titles[0].to_s.delete("[\"").delete("\"]")
            return body,0.77,file_name
        end

        def nyahentai
            puts "nyahentai"
        end
    end
end