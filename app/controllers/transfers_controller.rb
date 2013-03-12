class TransfersController < ApplicationController

  layout "l/layouts/admin"

  # GET /transfers
  # GET /transfers.xml
  def index
    authorize! :menage, :all
    @transfers = Transfer

    unless filter(:name).blank?
      @transfers = @transfers.
        where("`name` LIKE ?", "%#{filter(:name)}%")
    end
    unless filter(:recipients).blank?
      @transfers = @transfers.
        where("`recipients` LIKE ?", "%#{filter(:recipients)}%")
    end
    unless filter(:user_id).blank?
      @transfers = @transfers.
        where("`user_id` LIKE ?", "%#{filter(:user_id)}%")
    end
    unless filter(:token).blank?
      @transfers = @transfers.
        where("`token` LIKE ?", "%#{filter(:token)}%")
    end
    unless filter(:object_file_name).blank?
      @transfers = @transfers.
        where("`object_file_name` LIKE ?", "%#{filter(:object_file_name)}%")
    end
    unless filter(:expires_at).blank?
      @transfers = @transfers.
        where("`expires_at` LIKE ?", "%#{filter(:expires_at)}%")
    end
    
    @transfers = @transfers.order(sort_order) if sort_results?
    
    @transfers = @transfers.all.paginate page: params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @transfers }
    end
  end

  # GET /transfers/1
  # GET /transfers/1.xml
  def show
    authorize! :menage, :all
    @transfer = Transfer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def download
    @transfer = Transfer.find_by_token(params[:token])

    respond_to do |format|
      format.html { render layout: false }
      format.zip do
        head(:gone) and return if @transfer.expired?
        send_file @transfer.object.path 
      end
    end
  end

  # GET /transfers/new
  # GET /transfers/new.xml
  def new
    authorize! :menage, :all
    @transfer = Transfer.new(user: current_user)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @transfer }
    end
  end

  # GET /transfers/1/edit
  def edit
    authorize! :menage, :all
    @transfer = Transfer.find(params[:id])
  end

  # POST /transfers
  # POST /transfers.xml
  def create
    authorize! :menage, :all
    @transfer = Transfer.new(params[:transfer])
    @transfer.user = current_user

    respond_to do |format|
      if @transfer.save
        format.html { redirect_to(transfers_path, notice: I18n.t('create.success') ) }
        format.xml  { render xml: @transfer, status: :created, location: @transfer }
      else
        format.html { render action: "new" }
        format.xml  { render xml: @transfer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /transfers/1
  # PUT /transfers/1.xml
  def update
    authorize! :menage, :all
    @transfer = Transfer.find(params[:id])

    respond_to do |format|
      if @transfer.update_attributes(params[:transfer])
      format.html { redirect_to(transfers_path, notice: I18n.t('update.success') ) }
      format.xml  { head :ok }
      else
      format.html { render action: "edit" }
      format.xml  { render xml: @transfer.errors, status: :unprocessable_entity }
      end
    end
  end

  def file
    head :created
  end

  # DELETE /transfers/1
  # DELETE /transfers/1.xml
  def destroy
    authorize! :menage, :all
    @transfer = Transfer.find(params[:id])
    @transfer.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: I18n.t('delete.success') } 
      format.xml  { head :ok }
    end
  end
end
