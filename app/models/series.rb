class Series < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
end
