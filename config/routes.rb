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

    match 'items(-:folder)(/:partial)(.:format)', 
      partial: /true|false/,
      to: 'items#index',
      via: :get,
      as: :items,
      defaults: { partial: false }

    match 'items(-:folder)(.:format)', 
      to: 'items#create',
      via: :post,
      as: :items

    resources :items, except: [:index, :new, :create] do
      put :share, on: :member
    end

    match 'items/:id/download(/:style)/:name.:format', 
      to: 'items#download', 
      via: :get, 
      as: :download_item,
      defaults: { style: :original }

    resources :folders, only: [:create, :destroy] do 
      put :share, on: :member
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
    end

    match 'collaborators(.:format)', to: 'application#collaborators', as: :collaborators

    resources :groups
    resources :users
    match 'switch_lang/:lang', to: 'application#switch_lang', as:  :switch_lang, lang: locale_regex
    root to: 'items#index'
  end
  root to: 'items#index'
end
