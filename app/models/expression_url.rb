class ExpressionUrl < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :expression

  def self.find_url_match(id, url)
    match = ExpressionUrl.find(:first, :conditions => {:exp_id => id, :url => url})
    return match
  end
end
