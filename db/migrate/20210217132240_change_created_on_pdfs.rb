class ChangeCreatedOnPdfs < ActiveRecord::Migration[5.2]
  def change
    change_column_default :pdfs, :created, from: nil ,to: false
  end
end
