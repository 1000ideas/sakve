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

  def share
    @folder = Folder.find(params[:id])
    authorize! :share, @folder

    params[:with] ||= {}

    params[:with][:users].try(:each) do |user_id|
      user = User.where(id: user_id).first
      @folder.users << user if user && @folder.users.exclude?(user)
    end

    params[:with][:groups].try(:each) do |group_id|
      group = Group.where(id: group_id)
      @folder.groups << group if group && @folder.groups.exclude?(group)
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
