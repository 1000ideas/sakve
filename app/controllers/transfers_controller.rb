class TransfersController < ApplicationController

  # GET /transfers
  # GET /transfers.xml
  def index
    @bodycover = true
    authorize! :read, Transfer
    @transfer = Transfer.new(user: current_user)

    # @transfers = Transfer.active.for_user(current_user)

    respond_to do |format|
      format.html do
        if request.xhr?
          render layout: false
        else
          render
        end
      end
    end
  end

  def show
    @transfer = Transfer.find(params[:id])
    authorize! :update, @transfer

    respond_to do |format|
      format.js
    end
  end

  def status
    @transfer = Transfer.find(params[:id])
    authorize! :update, @transfer

    respond_to do |format|
      format.js
    end
  end

  def download
    @transfer = Transfer.find_by_token(params[:token])

    respond_to do |format|
      format.html do
        @download = true
        @bodycover = true
      end
      format.zip do
        head(:gone) and return if @transfer.expired?
        @transfer.statistics.create(client_ip: request.remote_ip, browser: request.user_agent)
        send_file @transfer.object.path, filename: @transfer.object_file_name, x_sendfile: true
      end
    end
  end

  def file_download
    @transfer = Transfer.find_by_token(params[:token])
    head(:gone) and return if @transfer.expired?
    @transfer.statistics.create(client_ip: request.remote_ip, browser: request.user_agent)
    send_file @transfer.object.path, filename: @transfer.object_file_name, x_sendfile: true
  end

  def save
    @transfer = Transfer.find(params[:id])
    authorize! :read, @transfer

    if request.post?
      @folder = Folder.find(params[:folder_id])
      authorize! :update, @folder
      @success = @folder.save_transfer(@transfer, current_user)
    end

    respond_to do |format|
      format.js
    end
  end

  # GET /transfers/1/edit
  def edit
    @transfer = Transfer.find(params[:id])
    authorize! :update, @transfer

    respond_to do |format|
      format.js
    end
   end

  # POST /transfers
  # POST /transfers.xml
  def create
    authorize! :create, Transfer
    @transfer = Transfer.new(params[:transfer])
    @transfer.user = current_user

    respond_to do |format|
      if @transfer.save
        format.html { redirect_to(transfers_path, notice: I18n.t('create.success') ) }
      else
        format.html { render action: "new" }
      end
      format.js
    end
  end

  # PUT /transfers/1
  # PUT /transfers/1.xml
  def update
    @transfer = Transfer.find(params[:id])
    authorize! :update, @transfer

    respond_to do |format|
      if @transfer.update_attributes(params[:transfer])
        format.html { redirect_to(transfers_path, notice: I18n.t('update.success') ) }
      else
        format.html { render action: "edit" }
      end
      format.js
    end
  end

  # DELETE /transfers/1
  # DELETE /transfers/1.xml
  def destroy
    @transfer = Transfer.find(params[:id])
    authorize! :destroy, @transfer
    @transfer.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: I18n.t('delete.success') }
      format.js
    end
  end
end
