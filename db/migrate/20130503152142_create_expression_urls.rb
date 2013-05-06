class CreateExpressionUrls < ActiveRecord::Migration
  def change
    create_table :expression_urls do |t|
      t.integer :exp_id, :null => false
      t.string :url
      t.string :display_label
      t.boolean :host_work
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`expression_urls` 
      ADD CONSTRAINT `eu_exp`
      FOREIGN KEY (`exp_id` )
      REFERENCES `perseus_blacklight`.`expressions` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `eu_exp_idx` (`exp_id` ASC) ;
    SQL
  end
end
