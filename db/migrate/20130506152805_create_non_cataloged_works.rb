class CreateNonCatalogedWorks < ActiveRecord::Migration
  def change
    create_table :non_cataloged_works do |t|
      t.string :urn, :null => false
      t.integer :textgroup_id, :null => false
      t.string :title
      t.string :ed_trans
      t.boolean :exp_edition
      t.boolean :exp_translation
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`non_cataloged_works` 
      ADD CONSTRAINT `ncw_tg`
      FOREIGN KEY (`textgroup_id` )
      REFERENCES `perseus_blacklight`.`textgroups` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `ncw_tg_idx` (`textgroup_id` ASC) ;
    SQL
  end
end
