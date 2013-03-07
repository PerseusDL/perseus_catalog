class Work < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :author

  has_many :expressions

  #def self.find_by_standard_id(id)
  #  found_id = Work.find_by_standard_id(id)
  #end

  def self.get_info(id)
    doc = Work.find_by_standard_id(id)
    doc_hash = doc.attributes
  end


end
