class CreateAtomError < ActiveRecord::Migration
  def change
    create_table :atom_errors do |t|
      t.string :standard_id, :null =>false
      t.integer :author_id
      t.string :title, :null => false
      t.string :language
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`atom_errors` 
      ADD CONSTRAINT `er_auth`
      FOREIGN KEY (`author_id` )
      REFERENCES `perseus_blacklight`.`authors` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `er_auth_idx` (`author_id` ASC) ;
    SQL
  end
end