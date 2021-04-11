class Pdf < ApplicationRecord
    has_many :images, dependent: :destroy
end
