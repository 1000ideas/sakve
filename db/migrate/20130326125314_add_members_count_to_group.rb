class AddMembersCountToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :members_count, :integer, null: false, default: 0
  end
end
