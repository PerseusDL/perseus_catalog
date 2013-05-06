class CreateAuthorUrls < ActiveRecord::Migration
  def change
    create_table :author_urls do |t|
      t.integer :author_id
      t.text :url
      t.string :display_label
      t.timestamps
    end

        execute <<-SQL
      ALTER TABLE `perseus_blacklight`.`author_urls` 
      ADD CONSTRAINT `url_auth`
      FOREIGN KEY (`author_id` )
      REFERENCES `perseus_blacklight`.`authors` (`id` )
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
      ADD INDEX `url_auth_idx` (`author_id` ASC) ;
    SQL
  end
end
