class AddUploadStatusToTransferFile < ActiveRecord::Migration
  def change
    add_column :transfer_files, :upload_status, :string, default: TransferFile.upload_statuses.first, null: false
  end
end
