class CreateExpression < ActiveRecord::Migration
  def change
    create_table :expressions do |t|
      t.integer :work_id, :null => false
      t.string :title
      t.string :alt_title
      t.string :abbr_title
      t.string :host_title
      t.integer :editor_id
      t.integer :translator_id
      t.string :language
      t.string :place_publ
      t.string :publisher
      t.year :date_publ
      t.year :date_mod
      t.string :edition
      t.string :phys_descr
      t.text :notes
      t.string :subjects
      t.string :cts_urn
      t.integer :series_id
      t.integer :page_start
      t.integer :page_end
      t.integer :word_count
      t.string :urls
      t.string :host_urls
      t.timestamps
    end

    
    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`expressions` 
      ADD CONSTRAINT `e_ed`
      FOREIGN KEY (`editor_id` )
      REFERENCES `perseus_blacklight`.`editors_or_translators` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `e_ed_idx` (`editor_id` ASC) ;
    SQL
    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`expressions` 
      ADD CONSTRAINT `e_trans`
      FOREIGN KEY (`translator_id` )
      REFERENCES `perseus_blacklight`.`editors_or_translators` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `e_trans_idx` (`translator_id` ASC) ;
    SQL
    
  end
end
