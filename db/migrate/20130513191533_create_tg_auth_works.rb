class CreateTgAuthWorks < ActiveRecord::Migration
  def change
    create_table :tg_auth_works do |t|
      t.integer :tg_id
      t.integer :auth_id
      t.integer :work_id
      t.timestamps
    end

  execute <<-SQL
    ALTER TABLE `perseus_blacklight`.`tg_auth_works` 
    ADD CONSTRAINT `taw_tg`
    FOREIGN KEY (`tg_id` )
    REFERENCES `perseus_blacklight`.`textgroups` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
    ADD INDEX `taw_tg_idx` (`tg_id` ASC) ;
  SQL

  execute <<-SQL
    ALTER TABLE `perseus_blacklight`.`tg_auth_works` 
    ADD CONSTRAINT `taw_aid`
    FOREIGN KEY (`auth_id` )
    REFERENCES `perseus_blacklight`.`authors` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
    ADD INDEX `taw_aid_idx` (`auth_id` ASC) ;
  SQL

  execute <<-SQL
    ALTER TABLE `perseus_blacklight`.`tg_auth_works` 
    ADD CONSTRAINT `taw_wid`
    FOREIGN KEY (`work_id` )
    REFERENCES `perseus_blacklight`.`works` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
    ADD INDEX `taw_wid_idx` (`work_id` ASC) ;
  SQL
  end
end
