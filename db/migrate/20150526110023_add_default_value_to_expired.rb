class AddDefaultValueToExpired < ActiveRecord::Migration
  def up
  	change_column_default :transfers, :expired, false
  end

  def down
  	change_column_default :transfers, :expired, nil
  end
end
