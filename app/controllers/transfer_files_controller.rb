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
        format.json { render json: @file, only: [:id, :token], methods: :name, status: :created, location: file_path(@file, format: :js) }
      else
        format.json { render json: @file.errors, status: :unprocessable_entity }
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

  def for_mustache(object)
    view_context.transfer_file_for_mustache(object)
  end
end
