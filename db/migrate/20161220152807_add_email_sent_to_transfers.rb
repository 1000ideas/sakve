class AddEmailSentToTransfers < ActiveRecord::Migration
  def up
    add_column :transfers, :email_sent, :boolean, default: false

    puts 'I gonna update email_sent column for all transfers...'
    Transfer.all.each do |t|
      t.update_attributes(email_sent: true)
    end
  end

  def down
    remove_column :transfers, :email_sent
  end
end
