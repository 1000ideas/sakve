class FoldersController < ApplicationController
  def create
    @folder = Folder.new(params[:folder])
    @folder.user = current_user
    authorize! :create, @folder


    if @folder.save
      @folders = Folder.global_root.try(:subfolders) || []
      @user_folders = Folder.user_root(current_user).try(:subfolders) || []
    end

    respond_to do |format|
      format.js
    end
  end

  def edit
    @folder = Folder.find(params[:id])
    authorize! :update, @folder

    respond_to do |format|
      format.html do
        if params[:subaction]
          render partial: "folders/edit/#{params[:subaction]}"
        end
      end
      format.js
    end
  end

  def update
    @folder = Folder.find(params[:id])
    authorize! :update, @folder

    @folder.update_attributes(params[:folder])
    respond_to do |format|
      format.js
    end
  end

  def download
    @folder = Folder.find(params[:id])
    authorize! :download, @folder

    respond_to do |format|
      format.js do
        @folder.async_recreate_zip_file
      end
      format.zip
    end
  end

  def share
    @folder = Folder.find(params[:id])
    authorize! :share, @folder

    if request.put?
      params[:with] ||= {}

      user_ids = params[:with][:users].try(:map, &:to_i)
      @folder.users = User.where(id: user_ids)

      group_ids = params[:with][:groups].try(:map, &:to_i)
      @folder.groups = Group.where(id: group_ids)
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @folder = Folder.find(params[:id])

    authorize! :destroy, @folder

    @folders = Folder.global_root.try(:subfolders) || []
    @user_folders = Folder.user_root(current_user).try(:subfolders) || []

    @folder.destroy

    respond_to do |format|
      format.js
    end
  end
end
