class FoldersController < ApplicationController
  def create
    @folder = Folder.new(params[:folder])
    @folder.user = current_user

    authorize! :create, @folder

    if @folder.save
      @folders = Folder.global_root.subfolders
      @user_folders = Folder.user_root(current_user).subfolders
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @folder = Folder.find(params[:id])

    authorize! :destroy, @folder

    @folders = Folder.global_root.subfolders
    @user_folders = Folder.user_root(current_user).subfolders

    @folder.destroy

    respond_to do |format|
      format.js
    end
  end
end
