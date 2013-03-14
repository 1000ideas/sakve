class FoldersController < ApplicationController
  def create
    @folder = Folder.new(params[:folder])
    @folder.user = current_user

    if @folder.save
      @folders = Folder.global_roots
      @user_folders = Folder.user_roots(current_user)
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @folder = Folder.find(params[:id])
    @folder.destroy

    respond_to do |format|
      format.js { render text: 'window.location.reload();' }
    end
  end
end
