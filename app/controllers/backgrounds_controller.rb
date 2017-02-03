class BackgroundsController < ApplicationController
  def index
    authorize! :read, Background

    @backgrounds = Background.all
  end

  def new
    @background = Background.new
    authorize! :create, @background
  end

  def create
    @background = Background.new(params[:background])
    authorize! :create, @background

    if @background.save
      redirect_to backgrounds_path, notice: 'Created'
    else
      redirect_to backgrounds_path, error: 'Error'
    end
  end

  def edit
    @background = Background.find(params[:id])
    authorize! :update, @background
  end

  def update
    @background = Background.find(params[:id])
    authorize! :update, @background
    @background.assign_attributes(params[:background])

    if @background.save
      redirect_to backgrounds_path, notice: 'Created'
    else
      redirect_to backgrounds_path, error: 'Error'
    end
  end

  def destroy
    @background = Background.find(params[:id])
    authorize! :destroy, @background

    if @background.destroy
      redirect_to backgrounds_path, notice: 'Deleted'
    else
      redirect_to backgrounds_path, error: 'Error'
    end
  end
end
