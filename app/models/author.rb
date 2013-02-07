class Author < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works


  def self.find_by_name_or_alt_name(name)
    found_name = Author.find_by_name(name) || Author.find_by_alt_names(name)
  end
end
