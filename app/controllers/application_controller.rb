class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    unless current_user
      session[:access_page] = request.path
      redirect_to new_user_session_url, alert:  exception.message
    else
      render action: '401'
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render action: '404'
  end


  protect_from_forgery
  before_filter :default_url_options, :set_locale

  layout :layout_by_resource

  def switch_lang
    session[:locale] = params[:lang]
    render nothing:  true
  end


  protected
  include L::FilterHelper

  private

  def set_locale
    if params[:locale]
      lang = params[:locale] || I18n.default_locale
      I18n.locale = lang.to_sym
    end
  end

  def default_url_options(options={})
    { locale:  I18n.locale }
  end


  def after_sign_in_path_for(resource)
    access_page, session[:access_page] = session[:access_page], nil
    access_page || root_path
  end

  def after_sign_out_path_for(resource)
    new_user_session_path
  end

  def layout_by_resource
    devise_controller? ? 'login' : 'standard'
  end

end
