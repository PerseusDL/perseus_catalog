class WordCount < ActiveRecord::Base
  #attr_accessible :description, :name

  belongs_to :author
end
