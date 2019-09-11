Rails.application.routes.draw do

  get 'attendance_fixes/new'

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
      get 'attendances/edit_end_ck'
      patch 'attendances/update_end_ck'
      get 'attendances/edit_change_ck'
      patch 'attendances/update_change_ck'
      get 'attendances/edit_fix_ck'
      patch 'attendances/update_fix_ck'
      get 'edit_basic_all'
      patch 'update_basic_all'
      get 'edit_all'
      patch 'update_all'
      get 'show_readonly'
    end
    resources :attendances, only: [:update, :create]
  end

  resources :attendances do
    member do
      get 'edit_over_work'
      patch 'update_over_work'
    end
  end

  resources :bases do
  end

end