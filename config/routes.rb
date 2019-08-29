Rails.application.routes.draw do

  #get 'bases/new'

  root 'static_pages#top'
  get '/signup', to: 'users#new'
  
  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  post   '/import', to: 'users#import'

  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
      get 'edit_basic_all'
      patch 'update_basic_all'
      get 'edit_all'
      patch 'update_all'
    end
    resources :attendances, only: :update
  end

  resources :bases do
  end

end