class CreateWork < ActiveRecord::Migration
  def change
    create_table :works do |t|
      t.string :standard_id, :null =>false
      t.integer :textgroup_id
      t.string :title, :null => false
      t.string :language
      t.integer :word_count
      t.timestamps
    end



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
