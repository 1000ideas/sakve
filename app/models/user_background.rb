class UserBackground < ActiveRecord::Base
  attr_accessible :background_id, :user_id

  belongs_to :user
  belongs_to :background
end
