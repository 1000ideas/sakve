class UserGroup < ActiveRecord::Base
  belongs_to :group, counter_cache: :members_count
  belongs_to :member, class_name: 'User'

  attr_accessible :group_id, :user_id

  validates :user_id, :group_id, presence: true

end
