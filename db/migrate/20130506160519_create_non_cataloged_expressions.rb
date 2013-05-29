class CreateNonCatalogedExpressions < ActiveRecord::Migration
  def change
    create_table :non_cataloged_expressions do |t|
      t.string :cts_urn, :null => false
      t.integer :work_id, :null => false
      t.string :title
      t.string :ed_trans
      t.string :var_type
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`non_cataloged_expressions` 
      ADD CONSTRAINT `nce_tg`
      FOREIGN KEY (`work_id` )
      REFERENCES `perseus_blacklight`.`works` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `nce_w_idx` (`work_id` ASC) ;
    SQL
  end
end
