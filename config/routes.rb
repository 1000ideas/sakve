Sakve::Application.routes.draw do

  locale_regex = %r{(#{I18n.available_locales.join('|')})}i

  scope '(:locale)', locale: locale_regex do
    devise_for :users,
      path: "",
      path_names: {
        :sign_in => 'login',
        :sign_out => 'logout',
        :sign_up => 'create',
        :password => 'reset_password',
        :confirmation => 'confirm_user',
        :registration => 'account'
      }

    get 'items(-:folder)(.:format)',
      to: 'items#index',
      via: :get,
      as: :items

    post 'items(-:folder)(.:format)',
      to: 'items#create',
      via: :post,
      as: :items

    resources :items, except: [:index, :new, :create] do
      collection do
        get :bulk_move, action: :bulk_edit, subaction: :move
        get :bulk_tags, action: :bulk_edit, subaction: :tags
        get :bulk_download
        put :bulk_update
        delete :bulk, action: :bulk_destroy
      end
      member do
        get :share
        put :share
        get 'download(/:style)/:name(.:format)',
          action: :download,
          as: :download,
          defaults: { style: :original }
        get :rename, action: :edit, subaction: :rename
        get :move, action: :edit, subaction: :move
        get :tags, action: :edit, subaction: :tags
      end
    end


    resources :folders, only: [:create, :update, :destroy] do
      member do
        get :rename, action: :edit, subaction: :rename
        get :move, action: :edit, subaction: :move
        get :download
        get :share
        put :share
      end
    end

    resources :tags, only: :index

    match 'transfers/:token(.:format)',
      to: 'transfers#download',
      via: :get,
      as: :download_transfer,
      constraints: {
        token: /[0-9a-f]{64}/i
      }

    resources :transfers, except: [:show, :new] do
      collection do
        resources :files, controller: :transfer_files, only: [:create, :destroy]
      end
      member do
        get :save
        post :save
      end
    end

    match 'collaborators(.:format)', to: 'application#collaborators', as: :collaborators


    # resources :groups
    resources :users do
      member do
        put :ban, ban: true
        put :unban, action: :ban, ban: false
      end
    end

    match 'change_folder', to: 'items#change_folder', via: :post

    scope controller: :application do
      get 'switch_lang/:lang', action: :switch_lang, as:  :switch_lang, lang: locale_regex
      post :context
      get :search
    end
    root to: 'items#index'
  end
  # root to: 'items#index'
end
