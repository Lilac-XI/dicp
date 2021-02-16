class CreatePdfs < ActiveRecord::Migration[5.2]
  def change
    create_table :pdfs do |t|
      t.string :file_name
      t.integer :image_size
      t.string :path
      t.string :url
      t.boolean :created
      t.timestamps
    end
  end
end
