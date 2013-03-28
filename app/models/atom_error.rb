class AtomError < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :author

  #def self.find_by_standard_id(id)
  #  found_id = Work.find_by_standard_id(id)
  #end


end