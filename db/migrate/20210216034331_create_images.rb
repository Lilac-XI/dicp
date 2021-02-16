class CreateImages < ActiveRecord::Migration[5.2]
  def change
    create_table :images do |t|
      t.integer :pdf_id
      t.string :url
      t.string :path
      t.boolean :access_success
      t.boolean :downloaded
      t.timestamps
    end
  end
end
