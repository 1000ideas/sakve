class ApplicationController < ActionController::Base
  # before_filter :miniprofiler
  before_filter :set_body_cover

  rescue_from CanCan::AccessDenied do |exception|
    (head(401) && return) if request.format != :html

    if current_user
      render action: '401', status: 401
    else
      session[:access_page] = request.path
      if ['/', *I18n.available_locales.map { |l| "/#{l}" }].include?(request.path)
        redirect_to new_user_session_url
      else
        redirect_to new_user_session_url, alert: exception.message
      end
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render action: '404', status: 404
  end

  protect_from_forgery
  before_filter :set_locale

  layout 'application'

  def context
    if selection_count == 1
      if selection.key?(:ids) && !selection[:ids].empty?
        @item = Item.find(selection[:ids].first)
      elsif selection.key?(:fids) && !selection[:fids].empty?
        @item = Folder.find(selection[:fids].first)
      elsif selection.key?(:tids) && !selection[:tids].empty?
        @item = Transfer.find(selection[:tids].first)
      end
    else
      @items = Item.where(id: selection[:ids])
      @folders = Folder.where(id: selection[:fids])
      @transfers = Transfer.where(id: selection[:tids])
      @can_destroy =
        @folders.accessible_by(current_ability, :destroy).any? ||
        @items.accessible_by(current_ability, :destroy).any? ||
        @transfers.accessible_by(current_ability, :destroy).any?

      @can_update =
        @folders.accessible_by(current_ability, :update).any? ||
        @items.accessible_by(current_ability, :update).any?
    end

    (head(:not_found) && return) unless request.xhr?

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

    @collaborators +=
      User.starts_with(params[:q])
          .where('`id` != ?', current_user.id)
          .limit(5)
          .map do |u|
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

  def ping
    if current_user
      head :ok
    else
      head :forbidden
    end
  end

  protected

  include L::FilterHelper

  private

  def stream_file(file, options = {})
    file = File.open(file) if file.is_a?(String)

    headers['Accept-Ranges'] = 'bytes'
    headers['Content-Transfer-Encoding'] = 'binary'

    if request.headers['Range']
      unit, range = request.headers['Range'].split '=', 2
      rstart, rend = range.split('-').map(&:to_i)
      rend ||= (file.size - 1)
      length = rend - rstart + 1
      (head(:not_modified) && return) if length <= 0
      headers['Content-Length'] = length.to_s
      headers['Content-Range'] = "bytes #{rstart}-#{rend}/#{file.size}"
      file.seek(rstart, IO::SEEK_SET)
    else
      length = file.size
      headers['Content-Length'] = length.to_s
      headers['Content-Range'] = "bytes 0-#{length - 1}/#{file.size}"
    end

    send_data file.read(length), options.merge(disposition: 'inline', status: 206)
  end

  def miniprofiler
    Rack::MiniProfiler.authorize_request
  end

  def set_locale
    lang = extract_locale_from_browser || params[:locale] || I18n.default_locale
    I18n.locale = lang.to_sym
  end

  def default_url_options(options = {})
    { locale: I18n.locale }
  end

  def after_sign_in_path_for(resource)
    access_page = session.delete(:access_page)
    access_page || transfers_path
  end

  def after_sign_out_path_for(resource)
    new_user_session_path
  end

  def search_query
    params[:search][:query] if params[:search]
  end

  def selection
    selection ||= {}
    params[:selection].each do |key, value|
      selection[key.to_sym] ||= []
      value.each { |id| selection[key.to_sym].push(id) }
    end
    selection
  end

  def selection_count
    count = 0
    selection.each do |_k, value|
      count += value.size
    end
    count
  end
  helper_method :selection

  def set_body_cover
    @bodycover = devise_controller?
    @bg = Background.where(active: true).to_a.sample
  end

  def extract_locale_from_browser
    l = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.scan(/^[a-z]{2}/).first
    l == 'pl' ? :pl : :en
  end
end
