class ItemsController < ApplicationController

  layout "l/layouts/admin"

  # GET /items
  # GET /items.xml
  def index
    authorize! :menage, :all
    @items = Item

    unless filter(:name).blank?
      @items = @items.
        where("`name` LIKE ?", "%#{filter(:name)}%")
    end
    unless filter(:type).blank?
      @items = @items.
        where("`type` LIKE ?", "%#{filter(:type)}%")
    end
    unless filter(:object_file_name).blank?
      @items = @items.
        where("`object_file_name` LIKE ?", "%#{filter(:object_file_name)}%")
    end
    unless filter(:user_id).blank?
      @items = @items.
        where("`user_id` LIKE ?", "%#{filter(:user_id)}%")
    end
    
    @items = @items.order(sort_order) if sort_results?
    
    @items = @items.all.paginate page: params[:page]

    respond_to do |format|
      format.html # index.html.erb
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

  # GET /items/new
  # GET /items/new.xml
  def new
    authorize! :menage, :all
    @item = Item.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @item }
    end
  end

  def multinew
    authorize! :menage, :all
    respond_to do |format|
      format.html 
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
        format.xml  { render xml: @item, status: :created, location: @item }
      else
        format.html { render action: "new" }
        format.xml  { render xml: @item.errors, status: :unprocessable_entity }
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
      format.xml  { head :ok }
    end
  end

  def download 
    authorize! :menage, :all
    @item = Item.find(params[:id])

    send_file @item.object.path(params[:style])
  end
end
