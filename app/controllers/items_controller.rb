class ItemsController < ApplicationController

  layout "standard"
  before_filter :create_new_folder

  # GET /items
  # GET /items.xml
  def index
    authorize! :menage, :all
    @folders = Folder.global_roots
    @user_folders = Folder.user_roots(current_user)
    @current_folder ||= @folders.first

    @items = Item.where(folder_id: @current_folder.try(:id)) 

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

  # GET /items/1
  # GET /items/1.xml
  def show
    authorize! :menage, :all
    @item = Item.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @item }
    end
  end

  # GET /items/1/edit
  def edit
    authorize! :menage, :all
    @item = Item.find(params[:id])
  end

  # POST /items
  # POST /items.xml
  def create
    authorize! :menage, :all
    @item = Item.new(params[:item])

    @item.user = current_user

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
    authorize! :menage, :all
    @item = Item.find(params[:id])

    respond_to do |format|
      if @item.update_attributes(params[:item])
      format.html { redirect_to(items_path, notice: I18n.t('update.success') ) }
      format.xml  { head :ok }
      else
      format.html { render action: "edit" }
      format.xml  { render xml: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    authorize! :menage, :all
    @item = Item.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: I18n.t('delete.success') } 
      format.js
    end
  end

  def download 
    authorize! :menage, :all
    @item = Item.find(params[:id])

    send_file @item.object.path(params[:style])
  end

  protected

  def create_new_folder
    @current_folder = Folder.where(id: params[:folder]).first
    @folder = Folder.new parent: @current_folder
  end
end
