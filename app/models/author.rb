class Author < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  has_many :atom_errors

  def self.find_by_name_or_alt_name(name)
    found_name = Author.find_by_name(name) || Author.find_by_alt_names(name)
  end

  def self.find_by_major_ids(id)
    found_id = Author.find(:first, :conditions => ["? in (phi_id, tlg_id, stoa_id)", id])
    return found_id
  end

  def self.get_info(id)
    doc = Author.find_by_name_or_alt_name(id)
    doc_hash = doc.attributes
  end
end
