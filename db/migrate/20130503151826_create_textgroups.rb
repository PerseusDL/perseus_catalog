class CreateTextgroups < ActiveRecord::Migration
  def change
    create_table :textgroups do |t|
      t.string :urn, :null => false
      t.string :urn_end, :null => false
      t.string :group_name
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`works` 
      ADD CONSTRAINT `w_tg`
      FOREIGN KEY (`textgroup_id` )
      REFERENCES `perseus_blacklight`.`textgroups` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `w_tg_idx` (`textgroup_id` ASC) ;
    SQL
  end
end
