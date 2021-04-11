class PdfController < ApplicationController
    def home
    end

    def create
        url = params[:download_link]
        check = Pdf.find_by(url: url)
        if check.nil? && url != "" && !url.nil?
            Pdf.create(url: url)
        end
        redirect_to "/"
    end
end
