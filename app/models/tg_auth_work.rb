class TgAuthWork < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  has_many :authors
  has_many :textgroups

  def self.find_row(auth_id, work_id, textgroup_id)
    found_row = TgAuthWork.find(:first, :conditions => ["tg_id=? and auth_id=? and work_id=?", textgroup_id, auth_id, work_id])
    return found_row
  end
end
