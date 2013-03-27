class CreateSeries < ActiveRecord::Migration
  def change
    create_table :series do |t|
      t.string :ser_title
      t.string :clean_title, :null=>false
      t.string :abbr_title
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`expressions` 
      ADD CONSTRAINT `e_series`
      FOREIGN KEY (`series_id` )
      REFERENCES `perseus_blacklight`.`series` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `e_series_idx` (`series_id` ASC) ;
    SQL
  end
end
