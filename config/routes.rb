Rails.application.routes.draw do
  root to: 'homes#show'

  mount GoodJob::Engine => 'good_job'

  resource :sessions, only: %i[new create destroy]
  resources :password_resets, only: %i[new create edit update]

  resource :settings, only: %i[show edit update]
  resolve('Setting') { [:settings] }

  resource :companies, only: %i[new create edit update]
  resolve('Company') { [:companies] }

  resources :users, only: %i[new create]

  namespace :me do
    resource :profile, only: %i[show edit update]
  end

  resources :customers do
    member do
      delete :archive
    end

    collection do
      get :daily
    end
  end
  resources :vehicles

  resources :places do
    collection do
      get :daily
    end
  end

  resources :transporters do
    collection do
      get :daily
    end
    scope module: :transporters do
      resources :absences, except: %i[index show]
    end
  end

  resources :daily_quests, only: %i[index show] do
    member do
      post :reset
      post :duplicate_week
      post 'optimize'
    end

    scope module: :daily_quests do
      resources :missions

      resources :steps, only: %i[edit update destroy] do
        member do
          post 'optimize'
        end
      end

      resources :transporters, only: [] do
        collection do
          post :send_all_plannings
        end

        member do
          post :send_planning
        end

        scope module: :transporters do
          resources :steps, only: %i[index]
        end
      end

      resources :missions, only: [] do
        scope module: :missions do
          resources :steps, only: %i[index update]
        end
      end
    end
  end

  namespace :addresses do
    resource :search, only: :show
  end
end
