Rails.application.routes.draw do
  default_url_options host: ENV['API_URL'] || 'http://www.deckie.io'

  # Removes all routes first in order to remove routes unnecessary for an API.
  devise_for :users, skip: :all

  scope module: :user do
    devise_scope :user do
      resource :user, controller: :registrations do
        post 'sign_in', to: 'sessions#create'

        resource  :profile,       only: [:show,   :update]
        resource  :preferences,   only: [:show,   :update]
        resource  :password,      only: [:create, :update]
        resource  :verification,  only: [:create, :update]
        resources :hosted_events, only: [:index,  :create]
        resources :submissions,   only: :index
        resources :notifications, only: :index

        post 'reset_notifications_count', to: 'notifications#reset_count'
      end
    end
  end

  shallow do
    resources :events, only: [:show, :update, :destroy] do
      resources :submissions, only: [:index, :create, :show, :destroy] do
        post 'confirm', on: :member
      end
      resources :comments, only: [:index, :create], controller: 'event/comments', shallow: true do
        resources :comments, only: [:index, :create], controller: 'comment/comments'
      end
    end
  end

  resources :comments, only: [:update, :destroy]

  resources :notifications, only: :show do
    post 'view', on: :member
  end

  resources :profiles, only: [:show, :update]
end
