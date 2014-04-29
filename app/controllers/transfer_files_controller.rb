class TransferFilesController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create
    authorize! :create, TransferFile

    @file = TransferFile.new(
      object: params[:object],
      token: params[:transfer].try(:[], :group_token),
      user: current_user
    )

    respond_to do |format|
      if @file.save
        format.json { render action: :create, status: :created, location: file_path(@file, format: :js) }
      else
        format.json { render action: :create, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @file = TransferFile.find(params[:id])
    authorize! :destroy, @file

    @file.destroy

    respond_to do |format|
      format.js
    end
  end

  private

end
