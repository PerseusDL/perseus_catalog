class Textgroup < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  has_many :authors

  def self.get_info(id)
    doc = Textgroup.find_by_urn(id)
    return doc
  end
end
