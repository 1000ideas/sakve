class UsersController < L::Admin::UsersController

  layout 'standard'

  def index
    authorize! :read, User
    @users = User.all.paginate :page => params[:page], :per_page => params[:per_page]||10
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
    if @user.save
      redirect_to users_path, notice: I18n.t('create.success')
    else
      render :action => :new
    end
  end

  def update
    @user = User.find(params[:id])
    authorize! :update, @user
    
    @user.updated_by = current_user

    if @user.update_attributes(params[:user])
      redirect_to users_path, notice: I18n.t('update.success')
    else
      render :action => :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    authorize! :destroy, @user
    @user.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: t('delete.success') }
      format.js
    end
  end

end
