class AddColumnPdfs < ActiveRecord::Migration[5.2]
  def change
    add_column :pdfs, :resized, :boolean
    change_column_default :pdfs, :resized, from: nil ,to: false
  end
end
