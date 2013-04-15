class ItemsController < ApplicationController

  layout "standard"

  # GET /items
  # GET /items.xml
  def index
    authorize! :read, Item
    @global_folder = Folder.global_root
    @user_folder = Folder.user_root(current_user)
    @shared_folders = Folder.shared_for(current_user)
    @current_folder = Folder.where(id: params[:folder]).first || (params[:folder] == 'user' ? @user_folder : @global_folder)
    @current_folder = nil if params[:folder] == 'shared'

    @item = Item.new(folder: @current_folder, user: current_user)

    if @current_folder
      @items = Item.where(folder_id: @current_folder.try(:id)) 
    elsif params[:folder] == 'shared'
      @items = Item.shared_for(current_user)
    end

    @folder = Folder.new parent: @current_folder, user: current_user, global: @current_folder.try(:global)

    respond_to do |format|
      format.html do
        if params[:partial]
          render @items
        else
          render
        end
      end
      format.xml  { render xml: @items }
    end
  end

  # GET /items/1.json
  def show
    @item = Item.find(params[:id])
    authorize! :read, @item

    respond_to do |format|
      format.json  { render json: @item }
      format.js
    end
  end

  def download 
    @item = Item.find(params[:id])
    authorize! :read, @item

    send_file @item.object.path(params[:style]), 
      filename: @item.name_for_download(params[:format]),
      content_type: @item.content_type(params[:style]),
      disposition: 'inline'
  rescue CanCan::AccessDenied
    send_data Item.access_denied_image(params[:style]), type: 'image/png'
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
    authorize! :update, @item

    respond_to do |format|
      format.js
    end
  end

  # POST /items
  # POST /items.xml
  def create
    @item = Item.new(params[:item])
    @item.user = current_user

    authorize! :create, @item

    respond_to do |format|
      if @item.save
        format.html { redirect_to(items_path, notice: I18n.t('create.success') ) }
        format.json  { render json: @item, status: :created, location: @item }
      else
        format.html { render action: "new" }
        format.json  { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.find(params[:id])
    authorize! :update, @item

    respond_to do |format|
      if @item.update_attributes(params[:item])
        format.html { redirect_to(items_path, notice: I18n.t('update.success') ) }
        format.js
      else
        format.html { render action: "edit" }
        format.js
      end
    end
  end

  def share
    @item = Item.find(params[:id])
    authorize! :share, @item

    params[:with] ||= {}

    params[:with][:users].try(:each) do |user_id|
      user = User.where(id: user_id).first
      @item.users << user if user && @item.users.exclude?(user)
    end

    params[:with][:groups].try(:each) do |group_id|
      group = Group.where(id: group_id)
      @item.groups << group if group && @item.groups.exclude?(group)
    end

    respond_to do |format|
      format.js
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find(params[:id])
    authorize! :destroy, @item
    @item.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: I18n.t('delete.success') } 
      format.js
    end
  end

  protected

end
