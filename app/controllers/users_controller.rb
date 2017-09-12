class UsersController < ApplicationController
  layout 'application'
  respond_to :html, :js

  def index
    authorize! :read, User
    @users = User.paginate(page: params[:page], per_page: 20)
  end

  def show
    @user = User.find(params[:id])
    authorize! :read, @user
  end

  def new
    @user = User.new
    authorize! :create, @user
  end

  def edit
    @user = User.find(params[:id])
    authorize! :update, @user
  end

  def create
    @user = User.new(params[:user])
    authorize! :create, @user
    respond_to do |format|
      if @user.save
        format.js
        format.html { redirect_to users_path }
      else
        format.js
        format.html { render 'new' }
      end
    end
  end

  def update
    @user = User.find(params[:id])
    authorize! :update, @user
    @user.updated_by = current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.js
        format.html { redirect_to users_path }
      else
        format.js
        format.html { render 'edit' }
      end
    end
  end

  def ban
    @user = User.find(params[:id])
    authorize! :manage, @user
    @user.updated_by = current_user
    if params[:ban] === true
      @user.ban!
    else
      @user.unban!
    end
  end

  def activate
    @user = User.find(params[:id])
    authorize! :manage, @user
    @user.updated_by = current_user
    @user.activate!
  end

  def destroy
    @user = User.find(params[:id])
    authorize! :destroy, @user
    @user.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: t('delete.success') }
    end
  end

end
