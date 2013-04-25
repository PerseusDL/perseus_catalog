class Author < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  has_many :atom_errors

  def self.find_by_name_or_alt_name(name)
    found_name = Author.find_by_name(name) || Author.find_by_alt_names(name)
  end

  def self.find_by_mads_or_alt_ids(id)
    found_id = Author.where(["mads_id RLIKE ?", id]).first
    unless found_id
      short_id = id.split(':').last
      found_id = Author.where(["alt_id RLIKE ?", short_id]).first
    end
    return found_id
  end

  def self.get_info(id)
    doc = Author.find_by_mads_or_alt_ids(id)
    doc_hash = doc.attributes
  end
end
