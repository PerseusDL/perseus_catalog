class Expression < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :work

  belongs_to_many :editors_or_translator

  belongs_to :series

end
