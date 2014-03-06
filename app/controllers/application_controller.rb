class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    head 401 and return if request.format != :html
    unless current_user
      session[:access_page] = request.path
      redirect_to new_user_session_url, alert:  exception.message
    else
      render action: '401', status: 401
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render action: '404', status: 404
  end


  protect_from_forgery
  before_filter :set_locale

  layout 'application'

  def context
    @folders = Folder.where( id: params[:selection].try(:[], :fids) )
    @items = Item.where( id: params[:selection].try(:[], :ids) )

    head :not_found and return unless request.xhr?

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def search
    @folders = Folder.allowed_for(current_user).search(search_query)
    @items = Item.allowed_for(current_user).search(search_query)

    respond_to do |format|
      format.html
    end
  end

  def switch_lang
    I18n.locale = session[:locale] = params[:lang].to_sym
    referer_params = Rails.application.routes.recognize_path(request.referer, method: :get)
    redirect_to Rails.application.routes.url_for(referer_params.merge(only_path: true, locale: I18n.locale))
  rescue ActionController::RoutingError
    redirect_to root_path
  end

  def collaborators
    authorize! :read, Group
    authorize! :read, User

    @collaborators = []

    @collaborators += User.
      starts_with(params[:q]).
      where('`id` != ?', current_user.id).
      limit(5).
      map do |u|
      {
        type: u.class.model_name.plural,
        type_name: u.class.model_name.human,
        name: u.to_s,
        id: u.id
      }
    end

    @collaborators += Group.starts_with(params[:q]).limit(5).map do |g|
      {
        type: g.class.model_name.plural,
        type_name: g.class.model_name.human,
        name: g.to_s,
        id: g.id
      }
    end

    respond_to do |format|
      format.json { render json: @collaborators }
    end
  end



  protected
  include L::FilterHelper

  private

  def set_locale
      lang = session[:locale] || params[:locale] || I18n.default_locale
      I18n.locale = lang.to_sym
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

  def search_query
    params[:search][:query] if params[:search]
  end


end
