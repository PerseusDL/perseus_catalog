class Work < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :author

  has_many :expressions

end
