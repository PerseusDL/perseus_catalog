class CreateAuthor < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.string :phi_id
      t.string :tlg_id
      t.string :stoa_id
      t.string :alt_id
      t.string :name, :null => false
      t.string :alt_parts
      t.string :dates
      t.string :alt_names      
      t.string :field_of_activity
      t.text :notes    
      t.timestamps
    end
  end
end
