class AddInfosHashToTransfers < ActiveRecord::Migration
  def change
    add_column :transfers, :infos_hash, :text

    Transfer.find(:all).each { |transfer| transfer.check_infos_hash }
  end
end