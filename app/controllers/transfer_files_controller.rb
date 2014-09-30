class TransferFilesController < ApplicationController
  prepend_before_filter :skip_timeout_logout

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create
    @file = TransferFile.new(
      object_file_name: params[:object].original_filename,
      token: params[:transfer].try(:[], :group_token),
      user: current_user
    )

    authorize! :create, @file

    options = {
      action: :create,
      status: :unprocessable_entity
    }


    if @file.save
      # current_tmpname = tmpname(@file.token)

      # FileUtils.ln params[:object].tempfile.path, current_tmpname
      current_tmpname = params[:object].tempfile.path


      CopyUploadedFileWorker.perform_async(@file.id, current_tmpname)
      options.merge!(status: :created, location: file_path(@file, format: :js))
    end

    respond_to do |format|
      format.json { render options  }
    end
  end

  # def create
  #   CopyUploadedFileWorker.perform_in(1.second, params[:object].tempfile.path)
  #   head :ok
  # end

  def destroy
    @file = TransferFile.find(params[:id])
    authorize! :destroy, @file

    @file.destroy

    respond_to do |format|
      format.js
    end
  end

  def bulk_destroy
    ids = params[:ids] || []
    TransferFile.where(id: ids).where(user_id: current_user.try(:id)).delete_all
    head :ok
  end

  private

  def skip_timeout_logout
    request.env["devise.skip_timeout"] = true
  end

  def tmpname(token)
    File.join(Dir::tmpdir, Dir::Tmpname.make_tmpname("upload", token))
  end

end
