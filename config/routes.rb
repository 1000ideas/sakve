Sakve::Application.routes.draw do
  scope '(:locale)' do 
    get "transfer_files/create"

    get "transfer_files/destroy"

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

    resources :items
    match 'items/:id/download/:style.:format', 
      to: 'items#download', 
      via: :get, 
      as: :download_file

    resources :tags

    match 'transfers/:token(.:format)', 
      to: 'transfers#download', 
      via: :get,
      as: :download_transfer,
      constraints: {
        token: /[0-9a-f]{64}/i
      }

    resources :transfers do
      collection do
        resources :files, controller: :transfer_files, only: [:create, :destroy]
      end
    end


    resources :users, controller: 'l/users' 
    resource :admin, controller: 'l/admins', only: [:show] do
      post :update_user, as: :update_user, on: :member
    end

    match 'switch_lang/:lang', to: 'application#switch_lang', as:  :switch_lang
    match 'search', to: 'application#search', as: :search
    root to: 'application#index'
  end
  root to: 'application#index'
end
