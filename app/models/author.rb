class Author < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works


  def self.find_by_name_or_alt_name(name)
    found_name = Author.find_by_name(name) || Author.find_by_alt_names(name)
  end

  def self.find_by_mads_or_alt_ids(id)
    found_id = Author.find_by_mads_id(id)
    unless found_id
      found_id = Author.where(["alt_id RLIKE ?", id]).first
    end
  end

  def self.get_info(id)
    doc = Author.find_by_mads_or_alt_ids(id)
    doc_hash = doc.attributes
  end
end
