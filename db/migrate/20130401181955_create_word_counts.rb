class CreateWordCounts < ActiveRecord::Migration
  def change
    create_table :word_counts do |t|
      t.integer :auth_id, :null => false
      t.integer :total_words
      t.integer :words_done
      t.integer :tufts_google
      t.integer :harvard_mellon
      t.integer :to_do
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`word_counts` 
      ADD CONSTRAINT `wc_auth`
      FOREIGN KEY (`auth_id` )
      REFERENCES `perseus_blacklight`.`authors` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `wc_auth_idx` (`auth_id` ASC) ;
    SQL
  end
end
