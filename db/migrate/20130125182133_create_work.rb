class CreateWork < ActiveRecord::Migration
  def change
    create_table :works do |t|
      t.string :standard_id, :null =>false
      t.string :clean_id, :null =>false
      t.integer :author_id
      t.string :title, :null => false
      t.string :language
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`works` 
      ADD CONSTRAINT `w_auth`
      FOREIGN KEY (`author_id` )
      REFERENCES `perseus_blacklight`.`authors` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `w_auth_idx` (`author_id` ASC) ;
    SQL

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`expressions` 
      ADD CONSTRAINT `e_work`
      FOREIGN KEY (`work_id` )
      REFERENCES `perseus_blacklight`.`works` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `e_work_idx` (`work_id` ASC) ;
    SQL
  end
end
