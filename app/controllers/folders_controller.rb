class FoldersController < ApplicationController
  def create
    @folder = Folder.new(params[:folder])
    @folder.user = current_user

    authorize! :create, @folder

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

    authorize! :destroy, @folder

    @folders = Folder.global_roots
    @user_folders = Folder.user_roots(current_user)

    @folder.destroy

    respond_to do |format|
      format.js
    end
  end
end
