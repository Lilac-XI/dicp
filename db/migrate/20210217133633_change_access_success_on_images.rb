class ChangeAccessSuccessOnImages < ActiveRecord::Migration[5.2]
  def change
    change_column_default :images, :access_success, from: false ,to: nil
  end
end
