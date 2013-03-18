class Expression < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :work

  belongs_to :editors_or_translator

  belongs_to :series


  def self.get_info(id)
    doc = Expression.find_by_cts_urn(id)
    doc_hash = doc.attributes
  end



end
