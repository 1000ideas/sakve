class BackgroundsController < ApplicationController
  def index
    authorize! :manage, Background

    @backgrounds = Background.all
    @background = Background.new
  end

  def create
    @background = Background.new(params[:background])

    if @background.save
      redirect_to backgrounds_path, notice: 'Created'
    else
      redirect_to backgrounds_path, error: 'Error'
    end
  end

  def destroy
    @background = Background.find(params[:id])

    if @background.destroy
      redirect_to backgrounds_path, notice: 'Deleted'
    else
      redirect_to backgrounds_path, error: 'Error'
    end
  end
end
