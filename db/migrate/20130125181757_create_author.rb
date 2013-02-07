class CreateAuthor < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.string :mads_id
      t.string :alt_id
      t.string :name, :null => false
      t.string :alt_parts
      t.string :dates
      t.string :alt_names      
      t.string :field_of_activity
      t.text :notes
      t.text :urls     
      t.timestamps
    end
  end
end
