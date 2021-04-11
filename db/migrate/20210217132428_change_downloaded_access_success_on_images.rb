class ChangeDownloadedAccessSuccessOnImages < ActiveRecord::Migration[5.2]
  def change
    change_column_default :images, :access_success, from: nil ,to: false
    change_column_default :images, :downloaded, from: nil ,to: false
  end
end
